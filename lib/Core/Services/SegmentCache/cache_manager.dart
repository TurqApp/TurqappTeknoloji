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
part 'cache_manager_runtime_part.dart';
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
  Future<void> init() => _SegmentCacheManagerRuntimeX(this).init();

  String get cacheDir => _SegmentCacheManagerRuntimeX(this).cacheDir;
  int get entryCount => _SegmentCacheManagerRuntimeX(this).entryCount;
  int get totalSizeBytes => _SegmentCacheManagerRuntimeX(this).totalSizeBytes;
  int get cachedVideoCount =>
      _SegmentCacheManagerRuntimeX(this).cachedVideoCount;
  int get totalSegmentCount =>
      _SegmentCacheManagerRuntimeX(this).totalSegmentCount;
  List<String> get recentlyPlayed =>
      _SegmentCacheManagerRuntimeX(this).recentlyPlayed;
  int get softLimitBytes => _SegmentCacheManagerRuntimeX(this).softLimitBytes;
  int get hardLimitBytes => _SegmentCacheManagerRuntimeX(this).hardLimitBytes;

  // ──────────────────────────── Cache Okuma ────────────────────────────

  /// Segment index'te varsa File döner, yoksa null.
  /// Disk varlığını senkron kontrol ETMEZ — index'e güvenir (startup recovery zaten tutarlılık sağlıyor).
  /// Bu sayede segment serving yolunda senkron I/O olmaz, segment geçişlerinde takılma azalır.
  File? getSegmentFile(String docID, String segmentKey) =>
      _SegmentCacheManagerRuntimeX(this).getSegmentFile(docID, segmentKey);

  /// m3u8 playlist disk'te varsa File döner, yoksa null.
  File? getPlaylistFile(String relativePath) =>
      _SegmentCacheManagerRuntimeX(this).getPlaylistFile(relativePath);

  /// Video entry varsa döner.
  VideoCacheEntry? getEntry(String docID) =>
      _SegmentCacheManagerRuntimeX(this).getEntry(docID);

  // ──────────────────────────── Cache Yazma ────────────────────────────

  // ──────────────────────────── State Yönetimi ────────────────────────────

  /// Video oynatılmaya başladığında çağır.
  void markPlaying(String docID) =>
      _SegmentCacheManagerRuntimeX(this).markPlaying(docID);

  /// İzlenme progress'ini güncelle. %90+ ise watched state'ine geç.
  void updateWatchProgress(String docID, double progress) =>
      _SegmentCacheManagerRuntimeX(this).updateWatchProgress(docID, progress);

  /// Erişim zamanını güncelle (cache hit'lerde).
  void touchEntry(String docID) =>
      _SegmentCacheManagerRuntimeX(this).touchEntry(docID);

  // ──────────────────────────── Eviction ────────────────────────────

  /// Hedef limit altına düşene kadar en düşük skorlu video'yu sil.
  Future<void> evictIfNeeded({int? targetBytes}) async {
    final target = targetBytes ?? softLimitBytes;
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
  void _scheduleEvictionIfNeeded() =>
      _SegmentCacheManagerRuntimeX(this)._scheduleEvictionIfNeeded();

  // ──────────────────────────── Cleanup ────────────────────────────

  @override
  Future<void> onClose() async {
    await _SegmentCacheManagerRuntimeX(this).disposeRuntime();
    super.onClose();
  }
}
