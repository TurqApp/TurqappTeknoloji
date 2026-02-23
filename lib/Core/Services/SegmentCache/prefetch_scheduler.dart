import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:turqappv2/Core/Services/video_emotion_config_service.dart';

import '../network_awareness_service.dart';
import 'cache_manager.dart';
import 'download_worker.dart';
import 'm3u8_parser.dart';
import 'network_policy.dart';

/// Wi-Fi prefetch kuyruğu.
///
/// Breadth-first strateji:
/// 1. Sonraki 5 videonun ilk 2 segmenti (hızlı başlangıç garantisi)
/// 2. Aktif videonun tüm segmentleri (tam cache)
/// 3. current+1, current+2'nin tüm segmentleri
class PrefetchScheduler extends GetxController {
  static const String _cdnOrigin = 'https://cdn.turqapp.com';
  static const int _fallbackBreadthCount = 5;
  static const int _fallbackBreadthSegments = 2;
  static const int _fallbackDepthCount = 3;
  static const int _fallbackMaxConcurrent = 2;
  static const int _fallbackFeedFullWindow = 5;
  static const int _fallbackFeedPrepWindow = 8;
  static const int _fallbackFeedPrepSegments = 2;
  static const int _wifiMinBreadthCount = 10;
  static const int _wifiMinBreadthSegments = 3;
  static const int _wifiMinDepthCount = 5;
  static const int _wifiMinMaxConcurrent = 4;
  static const int _wifiMinFeedFullWindow = 10;
  static const int _wifiMinFeedPrepWindow = 20;
  static const int _wifiMinFeedPrepSegments = 4;

  final List<_PrefetchJob> _queue = [];
  bool _paused = false;
  bool _mobileSeedMode = false;
  int _activeDownloads = 0;
  int _pendingDownloadBytes = 0;
  DownloadWorker? _worker;
  StreamSubscription? _workerSub;
  final http.Client _httpClient = http.Client();

  int get activeDownloads => _activeDownloads;
  int get queueSize => _queue.length;
  bool get isPaused => _paused;
  bool get _isOnWiFi {
    try {
      if (Get.isRegistered<NetworkAwarenessService>()) {
        return Get.find<NetworkAwarenessService>().isOnWiFi;
      }
    } catch (_) {}
    return CacheNetworkPolicy.canPrefetch;
  }

  int get _breadthCount {
    final base = _remote?.prefetchBreadthCount ?? _fallbackBreadthCount;
    return _isOnWiFi
        ? base < _wifiMinBreadthCount
            ? _wifiMinBreadthCount
            : base
        : base;
  }

  int get _breadthSegments {
    final base = _remote?.prefetchBreadthSegments ?? _fallbackBreadthSegments;
    return _isOnWiFi
        ? base < _wifiMinBreadthSegments
            ? _wifiMinBreadthSegments
            : base
        : base;
  }

  int get _depthCount {
    final base = _remote?.prefetchDepthCount ?? _fallbackDepthCount;
    return _isOnWiFi
        ? base < _wifiMinDepthCount
            ? _wifiMinDepthCount
            : base
        : base;
  }

  int get _maxConcurrent {
    if (_mobileSeedMode) return 1;
    final base = _remote?.prefetchMaxConcurrent ?? _fallbackMaxConcurrent;
    return _isOnWiFi
        ? base < _wifiMinMaxConcurrent
            ? _wifiMinMaxConcurrent
            : base
        : base;
  }

  int get _feedFullWindow => _isOnWiFi
      ? (_fallbackFeedFullWindow < _wifiMinFeedFullWindow
          ? _wifiMinFeedFullWindow
          : _fallbackFeedFullWindow)
      : _fallbackFeedFullWindow;

  int get _feedPrepWindow => _isOnWiFi
      ? (_fallbackFeedPrepWindow < _wifiMinFeedPrepWindow
          ? _wifiMinFeedPrepWindow
          : _fallbackFeedPrepWindow)
      : _fallbackFeedPrepWindow;

  int get _feedPrepSegments => _isOnWiFi
      ? (_fallbackFeedPrepSegments < _wifiMinFeedPrepSegments
          ? _wifiMinFeedPrepSegments
          : _fallbackFeedPrepSegments)
      : _fallbackFeedPrepSegments;

  VideoRemoteConfigService? get _remote {
    if (Get.isRegistered<VideoRemoteConfigService>()) {
      return Get.find<VideoRemoteConfigService>();
    }
    return null;
  }

  /// Video listesi ve aktif index güncellendiğinde çağrılır.
  /// Sadece Wi-Fi'de prefetch kuyruğu oluşturur.
  Future<void> updateQueue(List<String> docIDs, int currentIndex) async {
    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;

    _mobileSeedMode =
        _shouldEnableMobileSeedMode(docIDs: docIDs, cacheManager: cacheManager);

    if (!CacheNetworkPolicy.canPrefetch && !_mobileSeedMode) {
      pause();
      return;
    }

    _queue.clear();

    // Öncelik 1: Breadth-first — sonraki N videonun ilk K segmenti
    for (var i = 1; i <= _breadthCount; i++) {
      final idx = currentIndex + i;
      if (idx >= docIDs.length) break;
      final docID = docIDs[idx];

      // Zaten tamamen cache'lenmişse atla
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) continue;

      _queue.add(_PrefetchJob(
        docID: docID,
        maxSegments: _breadthSegments,
        priority: 0,
      ));
    }

    // Öncelik 2: Depth — aktif videonun tümü
    if (currentIndex >= 0 && currentIndex < docIDs.length) {
      final docID = docIDs[currentIndex];
      final entry = cacheManager.getEntry(docID);
      if (entry == null || !entry.isFullyCached) {
        _queue.add(_PrefetchJob(
          docID: docID,
          maxSegments: -1, // tümü
          priority: 1,
        ));
      }
    }

    // Öncelik 3: Depth — sonraki 2 videonun tümü
    for (var i = 1; i <= _depthCount - 1; i++) {
      final idx = currentIndex + i;
      if (idx >= docIDs.length) break;
      final docID = docIDs[idx];
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) continue;

      _queue.add(_PrefetchJob(
        docID: docID,
        maxSegments: -1,
        priority: 2,
      ));
    }

    // Sıralama: düşük priority önce
    _queue.sort((a, b) => a.priority.compareTo(b.priority));

    _processQueue();
  }

  /// Feed için agresif prefetch:
  /// 1) current dahil ilk 5 postu TAM cache
  /// 2) sonraki pencerede (varsayılan 8) ilk birkaç segmenti hazırlık
  Future<void> updateFeedQueue(List<String> docIDs, int currentIndex) async {
    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;

    _mobileSeedMode =
        _shouldEnableMobileSeedMode(docIDs: docIDs, cacheManager: cacheManager);

    if (!CacheNetworkPolicy.canPrefetch && !_mobileSeedMode) {
      pause();
      return;
    }
    if (docIDs.isEmpty) return;

    _queue.clear();

    final safeCurrent = currentIndex.clamp(0, docIDs.length - 1);
    final fullEnd =
        (safeCurrent + _feedFullWindow - 1).clamp(0, docIDs.length - 1);
    final prepEnd = (fullEnd + _feedPrepWindow).clamp(0, docIDs.length - 1);

    // Öncelik 0: ekranda gösterilecek ilk pencere TAM cache
    for (int i = safeCurrent; i <= fullEnd; i++) {
      final docID = docIDs[i];
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) continue;
      _queue.add(_PrefetchJob(
        docID: docID,
        maxSegments: -1,
        priority: 0,
      ));
    }

    // Öncelik 1: sonraki pencere hazırlık (ilk segmentler)
    for (int i = fullEnd + 1; i <= prepEnd; i++) {
      final docID = docIDs[i];
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) continue;
      _queue.add(_PrefetchJob(
        docID: docID,
        maxSegments: _feedPrepSegments,
        priority: 1,
      ));
    }

    _queue.sort((a, b) => a.priority.compareTo(b.priority));
    _processQueue();
  }

  /// Mobil veriye geçildiğinde çağrılır.
  /// Aktif indirmeleri de iptal eder (isolate kill + restart).
  void pause() {
    _paused = true;
    _queue.clear();

    // Aktif indirme varsa worker'ı durdur
    if (_activeDownloads > 0) {
      _workerSub?.cancel();
      _workerSub = null;
      _worker?.stop();
      _worker = null;
      _activeDownloads = 0;
    }

    debugPrint('[Prefetch] Paused — active downloads cancelled');
  }

  /// Wi-Fi'ye dönüldüğünde çağrılır.
  void resume() {
    _paused = false;
    debugPrint('[Prefetch] Resumed (Wi-Fi)');
    _processQueue();
  }

  // ──────────────────────────── Queue Processing ────────────────────────────

  Future<void> _processQueue() async {
    if (!CacheNetworkPolicy.canPrefetch && !_mobileSeedMode) {
      pause();
      return;
    }
    if (_paused || _queue.isEmpty) return;
    if (_activeDownloads >= _maxConcurrent) return;

    // Worker yoksa başlat
    if (_worker == null) {
      _worker = DownloadWorker();
      await _worker!.start();
      _workerSub = _worker!.results.listen(_onDownloadResult);
    }

    while (_queue.isNotEmpty && _activeDownloads < _maxConcurrent && !_paused) {
      final job = _queue.removeAt(0);
      await _processJob(job);
    }
  }

  Future<void> _processJob(_PrefetchJob job) async {
    if (!CacheNetworkPolicy.canPrefetch && !_mobileSeedMode) {
      pause();
      return;
    }

    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;

    try {
      // Master playlist'i çek (veya cache'den oku)
      final masterPath = 'Posts/${job.docID}/hls/master.m3u8';
      String? masterContent;

      final cachedMaster = cacheManager.getPlaylistFile(masterPath);
      if (cachedMaster != null) {
        masterContent = await cachedMaster.readAsString();
      } else {
        final url = '$_cdnOrigin/$masterPath';
        final response = await _httpClient
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          masterContent = response.body;
          await cacheManager.writePlaylist(masterPath, masterContent);
        }
      }

      if (masterContent == null) return;

      // Variant seç
      final variants = M3U8Parser.parseVariants(masterContent);
      final variant = M3U8Parser.bestVariant(variants);
      if (variant == null) return;

      // Variant playlist'i çek
      final masterDir =
          masterPath.substring(0, masterPath.lastIndexOf('/') + 1);
      final variantPath = '$masterDir${variant.uri}';
      String? variantContent;

      final cachedVariant = cacheManager.getPlaylistFile(variantPath);
      if (cachedVariant != null) {
        variantContent = await cachedVariant.readAsString();
      } else {
        final url = '$_cdnOrigin/$variantPath';
        final response = await _httpClient
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          variantContent = response.body;
          await cacheManager.writePlaylist(variantPath, variantContent);
        }
      }

      if (variantContent == null) return;

      final segmentUris = M3U8Parser.segmentUris(variantContent);

      // Entry meta güncelle
      cacheManager.updateEntryMeta(
        job.docID,
        '$_cdnOrigin/$masterPath',
        segmentUris.length,
      );

      // Cache'de olmayan segmentleri bul
      final variantDir =
          variantPath.substring(0, variantPath.lastIndexOf('/') + 1);
      final uncached = <String>[];
      for (final uri in segmentUris) {
        final segmentKey =
            '$variantDir$uri'.replaceFirst('Posts/${job.docID}/hls/', '');
        if (cacheManager.getSegmentFile(job.docID, segmentKey) == null) {
          uncached.add(uri);
        }
      }

      final entryForPolicy = cacheManager.getEntry(job.docID);
      final watchedProgress = entryForPolicy?.watchProgress ?? 0.0;
      final isUnwatched = watchedProgress <= 0.01;

      // İZLENMEYEN: mevcut agresif davranış korunur (tam cache olabilir).
      // İZLENEN: tüm segmentler asla inmez, ilerleyici ve sınırlı indirilir.
      final Iterable<String> toDownload;
      if (_mobileSeedMode && isUnwatched) {
        final mobileOrdered = _pickMobileSeedSegments(
          docID: job.docID,
          segmentUris: segmentUris,
          variantDir: variantDir,
          cacheManager: cacheManager,
        );
        final int mobileCap = job.maxSegments > 0
            ? job.maxSegments
            : mobileOrdered.length;
        toDownload = mobileOrdered.take(mobileCap);
      } else if (isUnwatched) {
        toDownload =
            job.maxSegments > 0 ? uncached.take(job.maxSegments) : uncached;
      } else {
        final preferred = _pickWatchedPrioritySegments(
          docID: job.docID,
          segmentUris: segmentUris,
          variantDir: variantDir,
          cacheManager: cacheManager,
          watchProgress: watchedProgress,
        );
        final int watchedCap = job.maxSegments > 0
            ? math.min(job.maxSegments, 3)
            : 3; // watched videoda full asla indirme
        toDownload = preferred.take(watchedCap);
      }

      for (final segUri in toDownload) {
        if (_paused) break;

        final segmentCdnUrl =
            '$_cdnOrigin/${variantDir.startsWith('/') ? variantDir.substring(1) : variantDir}$segUri';
        final segmentKey =
            '${variantDir.replaceFirst('Posts/${job.docID}/hls/', '')}$segUri';

        _activeDownloads++;
        _worker?.download(DownloadRequest(
          url: segmentCdnUrl,
          segmentKey: segmentKey,
          docID: job.docID,
        ));
      }
    } catch (e) {
      debugPrint('[Prefetch] Job failed for ${job.docID}: $e');
    }
  }

  bool _shouldEnableMobileSeedMode({
    required List<String> docIDs,
    required SegmentCacheManager cacheManager,
  }) {
    if (!CacheNetworkPolicy.isOnCellular) return false;
    if (docIDs.isEmpty) return false;

    // Keş havuzu boşsa (listede segmenti olan hiçbir entry yoksa) aç.
    for (final docID in docIDs.take(20)) {
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.cachedSegmentCount > 0) {
        return false;
      }
    }
    return true;
  }

  Iterable<String> _pickMobileSeedSegments({
    required String docID,
    required List<String> segmentUris,
    required String variantDir,
    required SegmentCacheManager cacheManager,
  }) {
    if (segmentUris.isEmpty) return const <String>[];

    final ordered = <String>[];
    final seen = <int>{};
    final total = segmentUris.length;

    // Seri kural: 1-4, 2-5, 3-6, ...
    for (int n = 1; n <= total; n++) {
      for (final seg in <int>[n, n + 3]) {
        if (seg > total) continue;
        final idx = seg - 1;
        if (!seen.add(idx)) continue;
        final uri = segmentUris[idx];
        final key = '$variantDir$uri'.replaceFirst('Posts/$docID/hls/', '');
        if (cacheManager.getSegmentFile(docID, key) == null) {
          ordered.add(uri);
        }
      }
    }
    return ordered;
  }

  Iterable<String> _pickWatchedPrioritySegments({
    required String docID,
    required List<String> segmentUris,
    required String variantDir,
    required SegmentCacheManager cacheManager,
    required double watchProgress,
  }) {
    if (segmentUris.isEmpty) return const <String>[];

    final total = segmentUris.length;
    final watchedSeg = _estimateWatchedSegment(
      watchProgress: watchProgress,
      totalSegments: total,
    );

    // Kural:
    // 1. segment izlenirken 3. segment
    // 2. segment izlenirken 5. segment
    // 3. segment izlenirken 6. segment
    // 4. segment izlenirken 7. segment
    // sonrası seri devam.
    final baseTarget = watchedSeg <= 1 ? 3 : watchedSeg + 3;

    final ordered = <String>[];
    final seen = <int>{};
    for (int seg = baseTarget; seg <= total; seg++) {
      final idx = seg - 1;
      if (!seen.add(idx)) continue;
      final uri = segmentUris[idx];
      final key = '$variantDir$uri'.replaceFirst('Posts/$docID/hls/', '');
      if (cacheManager.getSegmentFile(docID, key) == null) {
        ordered.add(uri);
      }
    }

    // Eğer tercih edilen pencerede hiç yoksa, boş dönme: mevcut uncached'ten devam et.
    if (ordered.isNotEmpty) return ordered;

    for (int idx = 0; idx < total; idx++) {
      final uri = segmentUris[idx];
      final key = '$variantDir$uri'.replaceFirst('Posts/$docID/hls/', '');
      if (cacheManager.getSegmentFile(docID, key) == null) {
        ordered.add(uri);
      }
    }
    return ordered;
  }

  int _estimateWatchedSegment({
    required double watchProgress,
    required int totalSegments,
  }) {
    final p = watchProgress.clamp(0.0, 1.0);
    final raw = (p * totalSegments).floor();
    return raw.clamp(1, totalSegments);
  }

  void _onDownloadResult(DownloadResult result) {
    _activeDownloads = (_activeDownloads - 1).clamp(0, _maxConcurrent * 2);

    if (result.success) {
      final bytes = result.bytes!;
      _trackDownloadBytes(bytes.length);
      final cacheManager = _getCacheManager();
      cacheManager?.writeSegment(
        result.docID,
        result.segmentKey,
        bytes,
      );
    } else {
      debugPrint(
          '[Prefetch] Download failed: ${result.docID}/${result.segmentKey} — ${result.error}');
    }

    // Kuyrukta daha var mı?
    _processQueue();
  }

  void _trackDownloadBytes(int bytes) {
    if (bytes <= 0) return;
    _pendingDownloadBytes += bytes;

    const int oneMb = 1024 * 1024;
    final int downloadMb = _pendingDownloadBytes ~/ oneMb;
    if (downloadMb <= 0) return;

    _pendingDownloadBytes -= downloadMb * oneMb;

    try {
      final network = Get.find<NetworkAwarenessService>();
      unawaited(network.trackDataUsage(uploadMB: 0, downloadMB: downloadMb));
    } catch (_) {}
  }

  // ──────────────────────────── Helpers ────────────────────────────

  SegmentCacheManager? _getCacheManager() {
    try {
      return Get.find<SegmentCacheManager>();
    } catch (_) {
      return null;
    }
  }

  @override
  void onClose() {
    _workerSub?.cancel();
    _worker?.stop();
    if (_pendingDownloadBytes > 0) {
      final int downloadMb = (_pendingDownloadBytes / (1024 * 1024)).ceil();
      try {
        final network = Get.find<NetworkAwarenessService>();
        unawaited(network.trackDataUsage(uploadMB: 0, downloadMB: downloadMb));
      } catch (_) {}
      _pendingDownloadBytes = 0;
    }
    _httpClient.close();
    super.onClose();
  }
}

class _PrefetchJob {
  final String docID;
  final int maxSegments; // -1 = tümü
  final int priority; // düşük = önce

  _PrefetchJob({
    required this.docID,
    required this.maxSegments,
    required this.priority,
  });
}
