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
    if (!Get.isRegistered<SegmentCacheManager>()) return null;
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

  /// Segment'i disk'e yaz, index'i güncelle.
  /// Per-key lock ile aynı segment için eş zamanlı yazımı engeller.
  Future<File> writeSegment(
      String docID, String segmentKey, Uint8List bytes) async {
    final lockKey = '$docID/$segmentKey';

    // Aynı segment için zaten yazım varsa onu bekleyip döndür
    final existing = _writeInFlight[lockKey];
    if (existing != null) return existing;

    final future = _writeSegmentInternal(docID, segmentKey, bytes);
    _writeInFlight[lockKey] = future;
    try {
      return await future;
    } finally {
      _writeInFlight.remove(lockKey);
    }
  }

  Future<File> _writeSegmentInternal(
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

    // Geçici dosyaya yaz, sonra rename.
    // flush: false — senkron disk fsync oynatma sırasında segment geçişlerinde takılma üretiyordu.
    // OS kendi buffer'ından yazacak; crash durumunda recovery zaten var.
    final tmpFile = File('${file.path}.tmp');
    await tmpFile.writeAsBytes(bytes, flush: false);
    try {
      await tmpFile.rename(file.path);
    } on FileSystemException {
      // Bazı Android cihazlarda rename sırasında parent path anlık kaybolabiliyor.
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: false);
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    }

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
    _scheduleEvictionIfNeeded();

    return file;
  }

  /// M3U8 playlist'i disk'e yaz (index'e segment olarak eklenmez).
  Future<File> writePlaylist(String relativePath, String content) async {
    final file = File('$_cacheDir/$relativePath');
    await file.parent.create(recursive: true);
    final tmpFile = File('${file.path}.tmp');
    await tmpFile.writeAsString(content, flush: false);
    try {
      await tmpFile.rename(file.path);
    } on FileSystemException {
      await file.parent.create(recursive: true);
      await file.writeAsString(content, flush: false);
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    }
    return file;
  }

  /// Entry'nin master playlist URL'sini ve toplam segment sayısını güncelle.
  void updateEntryMeta(String docID, String masterUrl, int totalSegmentCount) {
    final entry = _index.entries[docID];
    if (entry == null) return;

    if (entry.masterPlaylistUrl.isEmpty) {
      // masterPlaylistUrl boşsa yeni entry oluştur (aynı segments map'i paylaşır)
      _index.entries[docID] = VideoCacheEntry(
        docID: docID,
        masterPlaylistUrl: masterUrl,
        segments: entry.segments,
        totalSegmentCount: totalSegmentCount,
        totalSizeBytes: entry.totalSizeBytes,
        lastAccessedAt: entry.lastAccessedAt,
        watchProgress: entry.watchProgress,
        state: entry.state,
      );
    } else {
      // masterPlaylistUrl zaten var — sadece totalSegmentCount güncelle
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

  VideoCacheEntry? _findEvictionCandidate({bool preferLowQuality = false}) {
    VideoCacheEntry? worst;
    double worstScore = double.infinity;

    Iterable<VideoCacheEntry> candidates = _index.entries.values;
    if (preferLowQuality) {
      final lowQuality = candidates.where(_isLowQualityEntry).toList();
      if (lowQuality.isNotEmpty) {
        candidates = lowQuality;
      }
    }

    for (final entry in candidates) {
      final score = _evictionScore(entry);
      if (score < worstScore) {
        worstScore = score;
        worst = entry;
      }
    }
    return worst;
  }

  double _evictionScore(VideoCacheEntry entry) {
    return EvictionScoringEngine.score(
      EvictionScoreContext(
        state: entry.state,
        lastAccessedAt: entry.lastAccessedAt,
        isRecentlyPlayed: _recentlyPlayed.contains(entry.docID),
        watchProgress: entry.watchProgress,
        cachedSegmentCount: entry.cachedSegmentCount,
        totalSegmentCount: entry.totalSegmentCount,
        totalSizeBytes: entry.totalSizeBytes,
      ),
    );
  }

  bool _isLowQualityEntry(VideoCacheEntry entry) {
    if (entry.state == VideoCacheState.playing) return false;
    // Son koruma penceresindeki videolar low-quality havuzuna düşmesin.
    if (_recentlyPlayed.contains(entry.docID)) return false;
    if (entry.cachedSegmentCount <= 2) return true;
    if (entry.totalSegmentCount <= 0) return entry.cachedSegmentCount <= 3;
    final ratio = entry.cachedSegmentCount / entry.totalSegmentCount;
    if (ratio < 0.20) return true;
    if (entry.watchProgress <= 0.10 &&
        entry.state == VideoCacheState.partial &&
        entry.cachedSegmentCount <= 3) {
      return true;
    }
    return false;
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
    _persistTimer ??= Timer(const Duration(seconds: 5), () async {
      _persistTimer = null;
      if (_persistDirty) {
        _persistDirty = false;
        await persistIndex();
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
      try {
        await tmpFile.rename(file.path);
      } on FileSystemException {
        await file.parent.create(recursive: true);
        await file.writeAsString(json, flush: true);
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }
      }
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

    // Drift koruması: negatife düşmüşse reconcile et
    if (_index.totalSizeBytes < 0) {
      debugPrint(
          '[CacheManager] Recovery: totalSizeBytes was negative (${_index.totalSizeBytes}), reconciling');
      _reconcileTotalSize();
    }

    // Uncached/boş entry'leri temizle (0 segment, disk'te de yok)
    final emptyEntries = _index.entries.entries
        .where((e) => e.value.segments.isEmpty)
        .map((e) => e.key)
        .toList();
    for (final k in emptyEntries) {
      _index.entries.remove(k);
    }

    if (toRemove.isNotEmpty || emptyEntries.isNotEmpty) {
      debugPrint(
          '[CacheManager] Recovery: removed ${toRemove.length} stale + ${emptyEntries.length} empty entries');
      _markDirty();
    }
  }

  /// totalSizeBytes'ı tüm segment boyutlarından yeniden hesaplar.
  /// İnkremental hesaplamadaki drift'i düzeltir.
  void _reconcileTotalSize() {
    int entryTotal = 0;
    for (final entry in _index.entries.values) {
      int segTotal = 0;
      for (final seg in entry.segments.values) {
        segTotal += seg.sizeBytes;
      }
      if (entry.totalSizeBytes != segTotal) {
        entry.totalSizeBytes = segTotal;
      }
      entryTotal += segTotal;
    }
    if (_index.totalSizeBytes != entryTotal) {
      debugPrint(
          '[CacheManager] Reconcile: totalSizeBytes ${_index.totalSizeBytes} → $entryTotal');
      _index.totalSizeBytes = entryTotal;
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

  /// Kullanıcının tükettiği (izlenen) içerikleri cache'ten temizler.
  /// - watched state olanlar
  /// - veya watchProgress eşik üstü olanlar
  /// NOT: segmentRatio (cache doluluk oranı) izlenme göstergesi DEĞİLDİR,
  /// prefetch ile doldurulmuş ama hiç izlenmemiş videoları yanlışlıkla silmemek için kaldırıldı.
  Future<void> clearConsumedCache({double progressThreshold = 0.50}) async {
    final toRemove = <VideoCacheEntry>[];
    for (final entry in _index.entries.values) {
      final consumed = entry.state == VideoCacheState.watched ||
          entry.watchProgress >= progressThreshold;
      if (!consumed) continue;
      if (entry.state == VideoCacheState.playing) continue;
      toRemove.add(entry);
    }

    if (toRemove.isEmpty) return;

    for (final entry in toRemove) {
      await _evictEntry(entry);
    }

    _recentlyPlayed.removeWhere(
      (docID) => !_index.entries.containsKey(docID),
    );

    debugPrint(
      '[CacheManager] Consumed cache cleared: ${toRemove.length} entries',
    );
  }

  /// Kullanıcı cache kotasını (GB) runtime'da uygular.
  /// Phase 1 budget manager ile stream cache için yapılandırılmış soft/hard stop üretir.
  Future<void> setUserLimitGB(int gb) async {
    final profile = StorageBudgetManager.profileForPlanGb(gb);

    _userHardLimitBytes = profile.streamCacheHardStopBytes;
    _userSoftLimitBytes = profile.streamCacheSoftStopBytes;

    if (_index.totalSizeBytes > profile.streamCacheSoftStopBytes) {
      await evictIfNeeded(targetBytes: profile.streamCacheSoftStopBytes);
    }

    debugPrint(
      '[CacheManager] User cache quota applied: ${profile.planGb}GB '
      '(soft=${CacheMetrics.formatBytes(profile.streamCacheSoftStopBytes)}, '
      'hard=${CacheMetrics.formatBytes(profile.streamCacheHardStopBytes)})',
    );
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
