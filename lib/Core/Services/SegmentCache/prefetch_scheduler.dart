import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:turqappv2/Core/Services/VideoRemoteConfigService.dart';

import '../NetworkAwarenessService.dart';
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

  final List<_PrefetchJob> _queue = [];
  bool _paused = false;
  int _activeDownloads = 0;
  int _pendingDownloadBytes = 0;
  DownloadWorker? _worker;
  StreamSubscription? _workerSub;
  final http.Client _httpClient = http.Client();

  int get activeDownloads => _activeDownloads;
  int get queueSize => _queue.length;
  bool get isPaused => _paused;
  int get _breadthCount =>
      _remote?.prefetchBreadthCount ?? _fallbackBreadthCount;
  int get _breadthSegments =>
      _remote?.prefetchBreadthSegments ?? _fallbackBreadthSegments;
  int get _depthCount => _remote?.prefetchDepthCount ?? _fallbackDepthCount;
  int get _maxConcurrent =>
      _remote?.prefetchMaxConcurrent ?? _fallbackMaxConcurrent;

  VideoRemoteConfigService? get _remote {
    if (Get.isRegistered<VideoRemoteConfigService>()) {
      return Get.find<VideoRemoteConfigService>();
    }
    return null;
  }

  /// Video listesi ve aktif index güncellendiğinde çağrılır.
  /// Sadece Wi-Fi'de prefetch kuyruğu oluşturur.
  Future<void> updateQueue(List<String> docIDs, int currentIndex) async {
    if (!CacheNetworkPolicy.canPrefetch) {
      pause();
      return;
    }

    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;

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
    if (!CacheNetworkPolicy.canPrefetch) {
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
    if (!CacheNetworkPolicy.canPrefetch) {
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

      // maxSegments kadar indir
      final toDownload =
          job.maxSegments > 0 ? uncached.take(job.maxSegments) : uncached;

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
