import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Core/Services/VideoRemoteConfigService.dart';

import 'cache_metrics.dart';
import 'models.dart';

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
  late String _cacheDir;
  CacheIndex _index = CacheIndex();
  final CacheMetrics metrics = CacheMetrics();

  Timer? _persistTimer;
  bool _persistDirty = false;

  /// Son N oynatılan video — eviction'da korunur.
  final List<String> _recentlyPlayed = [];

  /// Başlatma: cache dizinini oluştur, index'i disk'ten yükle, recovery çalıştır.
  Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    _cacheDir = '${appDir.path}/hls_cache';
    await Directory(_cacheDir).create(recursive: true);
    await _loadIndex();
    await _recoverIndex();
    metrics.startPeriodicLog();
  }

  String get cacheDir => _cacheDir;
  int get entryCount => _index.entries.length;
  int get totalSizeBytes => _index.totalSizeBytes;
  int get totalSegmentCount =>
      _index.entries.values.fold(0, (sum, e) => sum + e.cachedSegmentCount);
  List<String> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  int get _softLimitBytes =>
      _remote?.cacheSoftLimitBytes ?? CacheIndex.softLimitBytes;
  int get _hardLimitBytes =>
      _remote?.cacheHardLimitBytes ?? CacheIndex.maxSizeBytes;
  int get _recentPlayCount => _remote?.cacheRecentProtectCount ?? 3;

  VideoRemoteConfigService? get _remote {
    if (Get.isRegistered<VideoRemoteConfigService>()) {
      return Get.find<VideoRemoteConfigService>();
    }
    return null;
  }

  // ──────────────────────────── Cache Okuma ────────────────────────────

  /// Segment disk'te varsa File döner, yoksa null.
  File? getSegmentFile(String docID, String segmentKey) {
    final entry = _index.entries[docID];
    if (entry == null) return null;
    final seg = entry.segments[segmentKey];
    if (seg == null) return null;
    final file = File(seg.diskPath);
    if (file.existsSync()) return file;
    // Index'te var ama disk'te yok — temizle
    entry.segments.remove(segmentKey);
    entry.totalSizeBytes -= seg.sizeBytes;
    _index.totalSizeBytes -= seg.sizeBytes;
    _markDirty();
    return null;
  }

  /// m3u8 playlist disk'te varsa File döner, yoksa null.
  File? getPlaylistFile(String relativePath) {
    final file = File('$_cacheDir/$relativePath');
    return file.existsSync() ? file : null;
  }

  /// Video entry varsa döner.
  VideoCacheEntry? getEntry(String docID) => _index.entries[docID];

  // ──────────────────────────── Cache Yazma ────────────────────────────

  /// Segment'i disk'e yaz, index'i güncelle.
  Future<File> writeSegment(
      String docID, String segmentKey, Uint8List bytes) async {
    // Entry yoksa oluştur
    _index.entries.putIfAbsent(
      docID,
      () => VideoCacheEntry(
        docID: docID,
        masterPlaylistUrl: '',
        state: VideoCacheState.fetching,
      ),
    );

    final entry = _index.entries[docID]!;
    final relativePath = 'Posts/$docID/hls/$segmentKey';
    final file = File('$_cacheDir/$relativePath');
    await file.parent.create(recursive: true);

    // Geçici dosyaya yaz, sonra rename (crash-safe)
    final tmpFile = File('${file.path}.tmp');
    await tmpFile.writeAsBytes(bytes, flush: true);
    await tmpFile.rename(file.path);

    // Eski segment varsa boyutunu düş
    final oldSeg = entry.segments[segmentKey];
    if (oldSeg != null) {
      entry.totalSizeBytes -= oldSeg.sizeBytes;
      _index.totalSizeBytes -= oldSeg.sizeBytes;
    }

    // Yeni segment ekle
    final segment = CachedSegment(
      segmentUri: segmentKey,
      diskPath: file.path,
      sizeBytes: bytes.length,
      cachedAt: DateTime.now(),
    );
    entry.segments[segmentKey] = segment;
    entry.totalSizeBytes += bytes.length;
    entry.lastAccessedAt = DateTime.now();
    _index.totalSizeBytes += bytes.length;

    // State güncelle
    if (entry.isFullyCached) {
      entry.state = VideoCacheState.ready;
    } else if (entry.segments.isNotEmpty) {
      entry.state = VideoCacheState.partial;
    }

    _markDirty();

    // Hard/soft limit aşıldıysa eviction tetikle
    if (_index.totalSizeBytes > _hardLimitBytes) {
      await evictIfNeeded(targetBytes: _hardLimitBytes);
    } else if (_index.totalSizeBytes > _softLimitBytes) {
      await evictIfNeeded(targetBytes: _softLimitBytes);
    }

    return file;
  }

  /// M3U8 playlist'i disk'e yaz (index'e segment olarak eklenmez).
  Future<File> writePlaylist(String relativePath, String content) async {
    final file = File('$_cacheDir/$relativePath');
    await file.parent.create(recursive: true);
    final tmpFile = File('${file.path}.tmp');
    await tmpFile.writeAsString(content, flush: true);
    await tmpFile.rename(file.path);
    return file;
  }

  /// Entry'nin master playlist URL'sini ve toplam segment sayısını güncelle.
  void updateEntryMeta(String docID, String masterUrl, int totalSegmentCount) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    entry.masterPlaylistUrl.isEmpty
        ? _index.entries[docID] = VideoCacheEntry(
            docID: docID,
            masterPlaylistUrl: masterUrl,
            segments: entry.segments,
            totalSegmentCount: totalSegmentCount,
            totalSizeBytes: entry.totalSizeBytes,
            lastAccessedAt: entry.lastAccessedAt,
            watchProgress: entry.watchProgress,
            state: entry.state,
          )
        : null;
    if (entry.totalSegmentCount != totalSegmentCount) {
      entry.totalSegmentCount = totalSegmentCount;
    }
    _markDirty();
  }

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
    entry.watchProgress = progress.clamp(0.0, 1.0);
    entry.lastAccessedAt = DateTime.now();
    if (progress >= 0.9 && entry.state == VideoCacheState.playing) {
      entry.state = VideoCacheState.watched;
    }
    _markDirty();
  }

  /// Erişim zamanını güncelle (cache hit'lerde).
  void touchEntry(String docID) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    entry.lastAccessedAt = DateTime.now();
  }

  // ──────────────────────────── Eviction ────────────────────────────

  /// Hedef limit altına düşene kadar en düşük skorlu video'yu sil.
  Future<void> evictIfNeeded({int? targetBytes}) async {
    final target = targetBytes ?? _softLimitBytes;
    while (_index.totalSizeBytes > target) {
      final candidate = _findEvictionCandidate();
      if (candidate == null) break; // Silinecek aday kalmadı
      await _evictEntry(candidate);
    }
  }

  VideoCacheEntry? _findEvictionCandidate() {
    VideoCacheEntry? worst;
    double worstScore = double.infinity;

    for (final entry in _index.entries.values) {
      final score = _evictionScore(entry);
      if (score < worstScore) {
        worstScore = score;
        worst = entry;
      }
    }
    return worst;
  }

  double _evictionScore(VideoCacheEntry entry) {
    // playing durumundaki videoyu asla silme
    if (entry.state == VideoCacheState.playing) return 1000.0;

    double score = 0;
    switch (entry.state) {
      case VideoCacheState.evictable:
        score = 0;
        break;
      case VideoCacheState.watched:
        score = 10;
        break;
      case VideoCacheState.partial:
        score = 20;
        break;
      case VideoCacheState.ready:
        score = 30;
        break;
      case VideoCacheState.fetching:
        score = 25;
        break;
      default:
        score = 5;
    }

    // Zamana dayalı bonus
    final ageMs =
        DateTime.now().difference(entry.lastAccessedAt).inMilliseconds;
    if (ageMs < 60000) {
      score += 50; // son 1 dk
    } else if (ageMs < 300000) {
      score += 30; // son 5 dk
    }

    // Son N video koruma bonusu (geri sarma UX)
    if (_recentlyPlayed.contains(entry.docID)) {
      score += 40;
    }

    return score;
  }

  Future<void> _evictEntry(VideoCacheEntry entry) async {
    // Disk'ten sil
    final dir = Directory('$_cacheDir/Posts/${entry.docID}');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    // Index'ten kaldır
    _index.totalSizeBytes -= entry.totalSizeBytes;
    _index.entries.remove(entry.docID);
    metrics.recordEviction();
    _markDirty();

    debugPrint(
        '[CacheManager] Evicted ${entry.docID} (${entry.totalSizeBytes} bytes)');
  }

  // ──────────────────────────── Persistence ────────────────────────────

  void _markDirty() {
    _persistDirty = true;
    _persistTimer ??= Timer(const Duration(seconds: 5), () {
      _persistTimer = null;
      if (_persistDirty) {
        _persistDirty = false;
        persistIndex();
      }
    });
  }

  /// Index'i JSON olarak disk'e yaz.
  Future<void> persistIndex() async {
    try {
      final file = File('$_cacheDir/index.json');
      final json = jsonEncode(_index.toJson());
      final tmpFile = File('${file.path}.tmp');
      await tmpFile.writeAsString(json, flush: true);
      await tmpFile.rename(file.path);
    } catch (e) {
      debugPrint('[CacheManager] Index persist error: $e');
    }
  }

  Future<void> _loadIndex() async {
    try {
      final file = File('$_cacheDir/index.json');
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _index = CacheIndex.fromJson(json);
      debugPrint(
          '[CacheManager] Index loaded: ${_index.entries.length} entries, '
          '${CacheMetrics.formatBytes(_index.totalSizeBytes)}');
    } catch (e) {
      debugPrint('[CacheManager] Index load error (starting fresh): $e');
      _index = CacheIndex();
    }
  }

  // ──────────────────────────── Recovery ────────────────────────────

  /// Startup'ta index vs disk tutarlılığını kontrol et.
  Future<void> _recoverIndex() async {
    // .tmp dosyalarını temizle (yarım kalmış indirmeler)
    await _cleanTempFiles(Directory(_cacheDir));

    // Index'teki entry'lerin disk'te olup olmadığını kontrol et
    final toRemove = <String>[];
    for (final entry in _index.entries.entries) {
      final dir = Directory('$_cacheDir/Posts/${entry.key}');
      if (!await dir.exists()) {
        toRemove.add(entry.key);
        continue;
      }

      // Her segment'in var olduğunu kontrol et
      final segToRemove = <String>[];
      for (final seg in entry.value.segments.entries) {
        if (!File(seg.value.diskPath).existsSync()) {
          segToRemove.add(seg.key);
        }
      }
      for (final k in segToRemove) {
        final removed = entry.value.segments.remove(k);
        if (removed != null) {
          entry.value.totalSizeBytes -= removed.sizeBytes;
          _index.totalSizeBytes -= removed.sizeBytes;
        }
      }
    }

    for (final k in toRemove) {
      final entry = _index.entries.remove(k);
      if (entry != null) {
        _index.totalSizeBytes -= entry.totalSizeBytes;
      }
    }

    if (toRemove.isNotEmpty) {
      debugPrint(
          '[CacheManager] Recovery: removed ${toRemove.length} stale entries');
      _markDirty();
    }
  }

  Future<void> _cleanTempFiles(Directory dir) async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.tmp')) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  /// Tüm cache içeriğini diskten ve index'ten temizler.
  Future<void> clearAllCache() async {
    final root = Directory(_cacheDir);
    if (await root.exists()) {
      await for (final entity in root.list()) {
        final name = entity.path.split('/').last;
        if (name == 'index.json') continue;
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    }

    _index = CacheIndex();
    _recentlyPlayed.clear();
    metrics.reset();
    await persistIndex();
    debugPrint('[CacheManager] All cache cleared');
  }

  // ──────────────────────────── Cleanup ────────────────────────────

  @override
  void onClose() {
    _persistTimer?.cancel();
    metrics.stopPeriodicLog();
    if (_persistDirty) {
      // Senkron kapatmada son persist denemesi
      persistIndex();
    }
    super.onClose();
  }
}
