import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/eviction_scoring_engine.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/video_emotion_config_service.dart';

import 'cache_metrics.dart';
import 'models.dart';

part 'cache_manager_eviction_part.dart';
part 'cache_manager_storage_part.dart';
part 'cache_manager_write_part.dart';

/// Segment seviyesinde HLS disk cache yöneticisi.
/// CDN path'ini mirror ederek disk'e yazar, index.json ile takip eder.
///
/// Disk yapısı:
/// ```
/// {appSupport}/hls_cache/
///   index.json
///   Posts/{docID}/hls/master.m3u8
///   Posts/{docID}/hls/720p/playlist.m3u8
///   Posts/{docID}/hls/720p/segment_0.ts
/// ```
class SegmentCacheManager extends GetxController {
  static SegmentCacheManager? maybeFind() {
    final isRegistered = Get.isRegistered<SegmentCacheManager>();
    if (!isRegistered) return null;
    return Get.find<SegmentCacheManager>();
  }

  static SegmentCacheManager ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SegmentCacheManager(), permanent: true);
  }

  late String _cacheDir;
  CacheIndex _index = CacheIndex();
  final CacheMetrics metrics = CacheMetrics();
  int? _userHardLimitBytes;
  int? _userSoftLimitBytes;

  Timer? _persistTimer;
  Timer? _reconcileTimer;
  bool _persistDirty = false;

  /// Per-key write lock — aynı segment için eş zamanlı yazımı engeller.
  final Map<String, Future<File>> _writeInFlight = {};

  /// Coalesced eviction — birden fazla writeSegment tek eviction tetikler.
  Future<void>? _evictionInFlight;

  /// Son N oynatılan video — eviction'da korunur.
  final List<String> _recentlyPlayed = [];
  final Map<String, double> _lastPersistedProgress = {};
  final Map<String, DateTime> _lastPersistedProgressAt = {};

  /// Başlatma: cache dizinini oluştur, index'i disk'ten yükle, recovery çalıştır.
  Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    _cacheDir = '${appDir.path}/hls_cache';
    await Directory(_cacheDir).create(recursive: true);
    await _loadIndex();
    // Recovery pahalı olabildiği için açılışı bloklamadan arka planda çalıştır.
    unawaited(_recoverIndex());
    metrics.startPeriodicLog();
    // Periyodik totalSizeBytes reconciliation — drift'i düzeltir (5 dakikada bir)
    _reconcileTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _reconcileTotalSize();
    });
  }

  String get cacheDir => _cacheDir;
  int get entryCount => _index.entries.length;
  int get totalSizeBytes => _index.totalSizeBytes;
  int get cachedVideoCount =>
      _index.entries.values.where((e) => e.cachedSegmentCount > 0).length;
  int get totalSegmentCount =>
      _index.entries.values.fold(0, (sum, e) => sum + e.cachedSegmentCount);
  List<String> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  int get softLimitBytes => _softLimitBytes;
  int get hardLimitBytes => _hardLimitBytes;
  int get _softLimitBytes =>
      _userSoftLimitBytes ??
      _remote?.cacheSoftLimitBytes ??
      CacheIndex.softLimitBytes;
  int get _hardLimitBytes =>
      _userHardLimitBytes ??
      _remote?.cacheHardLimitBytes ??
      CacheIndex.maxSizeBytes;
  int get _recentPlayCount {
    final remoteFloor = _remote?.cacheRecentProtectCount ?? 3;
    final budgetManager = StorageBudgetManager.maybeFind();
    if (budgetManager == null) return remoteFloor;
    return budgetManager.recentProtectionWindow(
      streamUsageBytes: _index.totalSizeBytes,
      remoteFloor: remoteFloor,
    );
  }

  VideoRemoteConfigService? get _remote => VideoRemoteConfigService.maybeFind();

  // ──────────────────────────── Cache Okuma ────────────────────────────

  /// Segment index'te varsa File döner, yoksa null.
  /// Disk varlığını senkron kontrol ETMEZ — index'e güvenir (startup recovery zaten tutarlılık sağlıyor).
  /// Bu sayede segment serving yolunda senkron I/O olmaz, segment geçişlerinde takılma azalır.
  File? getSegmentFile(String docID, String segmentKey) {
    final entry = _index.entries[docID];
    if (entry == null) return null;
    final seg = entry.segments[segmentKey];
    if (seg == null) return null;
    return File(seg.diskPath);
  }

  /// m3u8 playlist disk'te varsa File döner, yoksa null.
  File? getPlaylistFile(String relativePath) {
    final file = File('$_cacheDir/$relativePath');
    return file.existsSync() ? file : null;
  }

  /// Video entry varsa döner.
  VideoCacheEntry? getEntry(String docID) => _index.entries[docID];

  // ──────────────────────────── Cache Yazma ────────────────────────────

  // ──────────────────────────── State Yönetimi ────────────────────────────

  /// Video oynatılmaya başladığında çağır.
  void markPlaying(String docID) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    entry.state = VideoCacheState.playing;
    entry.lastAccessedAt = DateTime.now();

    // Son N oynatılan listeyi güncelle (eviction koruması)
    _recentlyPlayed.remove(docID);
    _recentlyPlayed.add(docID);
    if (_recentlyPlayed.length > _recentPlayCount) {
      _recentlyPlayed.removeAt(0);
    }

    _markDirty();
  }

  /// İzlenme progress'ini güncelle. %90+ ise watched state'ine geç.
  void updateWatchProgress(String docID, double progress) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    final normalized = progress.clamp(0.0, 1.0);
    entry.watchProgress = normalized;
    entry.lastAccessedAt = DateTime.now();
    if (normalized >= 0.9 && entry.state == VideoCacheState.playing) {
      entry.state = VideoCacheState.watched;
    }

    // Index yazımını agresif azalt: %3 değişim veya 6 sn'de bir.
    final lastProgress = _lastPersistedProgress[docID] ?? -1.0;
    final lastAt = _lastPersistedProgressAt[docID];
    final now = DateTime.now();
    final changedEnough = (normalized - lastProgress).abs() >= 0.03;
    final timeEnough = lastAt == null || now.difference(lastAt).inSeconds >= 6;
    final reachedEdge = normalized >= 0.98 || normalized <= 0.02;

    if (changedEnough || timeEnough || reachedEdge) {
      _lastPersistedProgress[docID] = normalized;
      _lastPersistedProgressAt[docID] = now;
      _markDirty();
    }
  }

  /// Erişim zamanını güncelle (cache hit'lerde).
  void touchEntry(String docID) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    entry.lastAccessedAt = DateTime.now();
    _markDirty();
  }

  // ──────────────────────────── Eviction ────────────────────────────

  /// Hedef limit altına düşene kadar en düşük skorlu video'yu sil.
  Future<void> evictIfNeeded({int? targetBytes}) async {
    final target = targetBytes ?? _softLimitBytes;
    while (_index.totalSizeBytes > target) {
      if (cachedVideoCount <= ContentPolicy.minGlobalCachedVideos) {
        break;
      }
      final candidate = _findEvictionCandidate(preferLowQuality: true);
      if (candidate == null) break; // Silinecek aday kalmadı
      await _evictEntry(candidate);
    }
  }

  /// Coalesced eviction: birden fazla writeSegment aynı anda eviction tetiklerse
  /// tek bir eviction çalışır, diğerleri aynı Future'ı bekler.
  void _scheduleEvictionIfNeeded() {
    if (_index.totalSizeBytes <= _softLimitBytes) return;
    if (_evictionInFlight != null) return; // zaten çalışıyor

    final target = _index.totalSizeBytes > _hardLimitBytes
        ? _hardLimitBytes
        : _softLimitBytes;

    _evictionInFlight = evictIfNeeded(targetBytes: target).whenComplete(() {
      _evictionInFlight = null;
    });
  }

  // ──────────────────────────── Cleanup ────────────────────────────

  @override
  Future<void> onClose() async {
    _persistTimer?.cancel();
    _reconcileTimer?.cancel();
    metrics.stopPeriodicLog();
    if (_persistDirty) {
      _persistDirty = false;
      await persistIndex();
    }
    super.onClose();
  }
}
