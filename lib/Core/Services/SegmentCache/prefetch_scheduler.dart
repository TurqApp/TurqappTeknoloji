import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_policy_engine.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/prefetch_scoring_engine.dart';
import 'package:turqappv2/Core/Services/video_telemetry_service.dart';
import 'package:turqappv2/Core/Services/video_emotion_config_service.dart';

import '../network_awareness_service.dart';
import 'cache_manager.dart';
import 'download_worker.dart';
import 'm3u8_parser.dart';
import 'network_policy.dart';

/// Wi-Fi prefetch kuyruğu.
///
/// Breadth-first strateji:
/// 1. Sonraki videolarda ilk 2 segment hazır
/// 2. Aktif videoda ilk 2 segment hazır
/// 3. İzleme sırasında yalnızca 1 sonraki segment hazırlanır
class PrefetchScheduler extends GetxController {
  static PrefetchScheduler ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PrefetchScheduler(), permanent: permanent);
  }

  static PrefetchScheduler? maybeFind() {
    final isRegistered = Get.isRegistered<PrefetchScheduler>();
    if (!isRegistered) return null;
    return Get.find<PrefetchScheduler>();
  }

  static const String _cdnOrigin = 'https://cdn.turqapp.com';
  static const Map<String, String> _cdnHeaders = {
    'X-Turq-App': 'turqapp-mobile',
    'Referer': '$_cdnOrigin/',
  };
  static const int _targetReadySegments = 2;
  // +5/-5 kuralı: önündeki 5 videonun min 2 segmenti hazır olmalı
  static const int _fallbackBreadthCount = 5;
  static const int _fallbackDepthCount = 3;
  static const int _fallbackMaxConcurrent = 2;
  static const int _fallbackFeedFullWindow = 15;
  static const int _fallbackFeedPrepWindow = 8;
  static const int _wifiMinBreadthCount = 12;
  static const int _wifiMinDepthCount = 7;
  static const int _wifiMinMaxConcurrent = 4;
  static const int _wifiMinFeedFullWindow = 15;
  static const int _wifiMinFeedPrepWindow = 20;

  final List<_PrefetchJob> _queue = [];
  bool _paused = false;
  bool _mobileSeedMode = false;
  int _activeDownloads = 0;
  int _pendingDownloadBytes = 0;
  final Map<String, DateTime> _jobEnqueuedAt = {};
  List<String> _lastFeedDocIDs = const [];
  int _lastFeedCurrentIndex = 0;
  int _lastFeedReadyCount = 0;
  int _lastFeedWindowCount = 0;
  double _lastFeedReadyRatio = 0.0;
  int _queueLatencySamples = 0;
  double _avgQueueDispatchLatencyMs = 0.0;
  String? _lastPrefetchHealthSignature;
  DownloadWorker? _worker;
  StreamSubscription? _workerSub;
  Timer? _watchdogTimer;
  final http.Client _httpClient = http.Client();

  int get activeDownloads => _activeDownloads;
  int get queueSize => _queue.length;
  bool get isPaused => _paused;
  bool get isMobileSeedMode => _mobileSeedMode;
  double get feedReadyRatio => _lastFeedReadyRatio;
  int get feedReadyCount => _lastFeedReadyCount;
  int get feedWindowCount => _lastFeedWindowCount;
  double get avgQueueDispatchLatencyMs => _avgQueueDispatchLatencyMs;
  int get maxConcurrentDownloads => _maxConcurrent;
  bool get _isOnWiFi {
    try {
      final network = NetworkAwarenessService.maybeFind();
      if (network != null) {
        return network.isOnWiFi;
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

  VideoRemoteConfigService? get _remote => VideoRemoteConfigService.maybeFind();

  /// Video listesi ve aktif index güncellendiğinde çağrılır.
  /// Sadece Wi-Fi'de prefetch kuyruğu oluşturur.
  Future<void> updateQueue(List<String> docIDs, int currentIndex) async {
    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;
    if (docIDs.isEmpty) return;
    final safeCurrent = currentIndex.clamp(0, docIDs.length - 1);
    final currentDocId = docIDs[safeCurrent];

    _mobileSeedMode =
        _shouldEnableMobileSeedMode(docIDs: docIDs, cacheManager: cacheManager);

    if (!CacheNetworkPolicy.canPrefetch && !_mobileSeedMode) {
      pause();
      return;
    }

    _queue.clear();
    _jobEnqueuedAt.clear();

    // Öncelik 1: Breadth-first — sonraki N videonun ilk K segmenti
    for (var i = 1; i <= _breadthCount; i++) {
      final idx = safeCurrent + i;
      if (idx >= docIDs.length) break;
      final docID = docIDs[idx];

      // Zaten tamamen cache'lenmişse atla
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) continue;

      _queue.add(_PrefetchJob(
        docID: docID,
        maxSegments: _targetReadySegments,
        priority: 0,
        sortScore: _buildJobScore(
          currentIndex: safeCurrent,
          currentDocId: currentDocId,
          targetIndex: idx,
          priority: 0,
          watchProgress: entry?.watchProgress ?? 0.0,
          cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
          totalSegmentCount: entry?.totalSegmentCount ?? 0,
        ),
      ));
      _jobEnqueuedAt[docID] = DateTime.now();
    }

    // Öncelik 2: Aktif videoda ilk 2 segment
    if (safeCurrent >= 0 && safeCurrent < docIDs.length) {
      final docID = docIDs[safeCurrent];
      final entry = cacheManager.getEntry(docID);
      if (entry == null || !entry.isFullyCached) {
        _queue.add(_PrefetchJob(
          docID: docID,
          maxSegments: _targetReadySegments,
          priority: 1,
          sortScore: _buildJobScore(
            currentIndex: safeCurrent,
            currentDocId: currentDocId,
            targetIndex: safeCurrent,
            priority: 1,
            watchProgress: entry?.watchProgress ?? 0.0,
            cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
            totalSegmentCount: entry?.totalSegmentCount ?? 0,
          ),
        ));
        _jobEnqueuedAt[docID] = DateTime.now();
      }
    }

    // Öncelik 3: Sonraki videolarda ilk 2 segment
    for (var i = 1; i <= _depthCount - 1; i++) {
      final idx = safeCurrent + i;
      if (idx >= docIDs.length) break;
      final docID = docIDs[idx];
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) continue;

      _queue.add(_PrefetchJob(
        docID: docID,
        maxSegments: _targetReadySegments,
        priority: 2,
        sortScore: _buildJobScore(
          currentIndex: safeCurrent,
          currentDocId: currentDocId,
          targetIndex: idx,
          priority: 2,
          watchProgress: entry?.watchProgress ?? 0.0,
          cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
          totalSegmentCount: entry?.totalSegmentCount ?? 0,
        ),
      ));
      _jobEnqueuedAt[docID] = DateTime.now();
    }

    // -5 kuralı: gerideki 5 videonun izlenen kısmını cache'de tut
    // (eviction korumasını desteklemek için touchEntry çağır)
    for (var i = 1; i <= 5; i++) {
      final idx = safeCurrent - i;
      if (idx < 0) break;
      if (idx < docIDs.length) {
        cacheManager.touchEntry(docIDs[idx]);
      }
    }

    // Sıralama: düşük priority önce
    _queue.sort(_compareJobs);
    _publishPrefetchHealthIfNeeded();

    _processQueue();
  }

  /// Feed için prefetch:
  /// 1) Açılışta ilk 15 videonun ilk 2 segmenti
  /// 2) Scroll sırasında current etrafında ±5 video için ilk 2 segment
  /// 3) Sonraki pencere için ek hazırlık (2 segment)
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
    _jobEnqueuedAt.clear();

    final safeCurrent = currentIndex.clamp(0, docIDs.length - 1);
    _lastFeedDocIDs = List<String>.from(docIDs);
    _lastFeedCurrentIndex = safeCurrent;
    final aroundStart = (safeCurrent - 5).clamp(0, docIDs.length - 1);
    final aroundEnd = (safeCurrent + 5).clamp(0, docIDs.length - 1);
    final initialEnd = (safeCurrent + _feedFullWindow - 1).clamp(
      0,
      docIDs.length - 1,
    );
    final prepEnd = (initialEnd + _feedPrepWindow).clamp(0, docIDs.length - 1);

    final queued = <String>{};
    void addJob(int index, int priority) {
      if (index < 0 || index >= docIDs.length) return;
      final docID = docIDs[index];
      if (!queued.add(docID)) return;
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) return;
      _queue.add(_PrefetchJob(
        docID: docID,
        maxSegments: _targetReadySegments,
        priority: priority,
        sortScore: _buildJobScore(
          currentIndex: safeCurrent,
          currentDocId: docIDs[safeCurrent],
          targetIndex: index,
          priority: priority,
          watchProgress: entry?.watchProgress ?? 0.0,
          cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
          totalSegmentCount: entry?.totalSegmentCount ?? 0,
        ),
      ));
      _jobEnqueuedAt[docID] = DateTime.now();
    }

    // Öncelik 0A: açılış/konum penceresi (ilk 15 içerik hazır olsun)
    for (int i = safeCurrent; i <= initialEnd; i++) {
      addJob(i, 0);
    }

    // Öncelik 0B: current etrafında ±5 her zaman hazır
    for (int i = aroundStart; i <= aroundEnd; i++) {
      addJob(i, 0);
    }

    // Öncelik 1: ileri hazırlık penceresi
    for (int i = initialEnd + 1; i <= prepEnd; i++) {
      addJob(i, 1);
    }

    // -5 kuralı: gerideki 5 videonun cache'ini koru
    for (var i = 1; i <= 5; i++) {
      final idx = safeCurrent - i;
      if (idx < 0) break;
      if (idx < docIDs.length) {
        cacheManager.touchEntry(docIDs[idx]);
      }
    }

    _queue.sort(_compareJobs);
    _updateFeedReadyRatio();
    _publishPrefetchHealthIfNeeded();
    _processQueue();
  }

  int _compareJobs(_PrefetchJob a, _PrefetchJob b) {
    final scoreCompare = b.sortScore.compareTo(a.sortScore);
    if (scoreCompare != 0) return scoreCompare;
    return a.priority.compareTo(b.priority);
  }

  double _buildJobScore({
    required int currentIndex,
    required String currentDocId,
    required int targetIndex,
    required int priority,
    required double watchProgress,
    required int cachedSegmentCount,
    required int totalSegmentCount,
  }) {
    final session = VideoTelemetryService.instance.activeSessionSnapshot(
      currentDocId,
    );
    return PrefetchScoringEngine.score(
      PrefetchScoreContext(
        basePriority: priority,
        currentIndex: currentIndex,
        targetIndex: targetIndex,
        isOnWiFi: _isOnWiFi,
        mobileSeedMode: _mobileSeedMode,
        feedReadyRatio: _lastFeedReadyRatio,
        watchProgress: watchProgress,
        cachedSegmentCount: cachedSegmentCount,
        totalSegmentCount: totalSegmentCount,
        sessionWatchTimeSeconds: session?.watchTimeSeconds ?? 0.0,
        sessionCompletionRate: session?.completionRate ?? 0.0,
        sessionRebufferRatio: session?.rebufferRatio ?? 0.0,
        sessionHasFirstFrame: session?.hasFirstFrame ?? false,
        sessionIsAudible: session?.isAudible ?? false,
        sessionHasStableFocus: session?.hasStableFocus ?? false,
      ),
    );
  }

  /// Mobil veriye geçildiğinde çağrılır.
  /// Aktif indirmeleri de iptal eder (isolate kill + restart).
  void pause() {
    _paused = true;
    _queue.clear();
    _jobEnqueuedAt.clear();

    // Aktif indirme varsa worker'ı durdur
    if (_activeDownloads > 0) {
      _workerSub?.cancel();
      _workerSub = null;
      _worker?.stop();
      _worker = null;
      _activeDownloads = 0;
    }

    debugPrint('[Prefetch] Paused — active downloads cancelled');
    _publishPrefetchHealthIfNeeded(force: true);
  }

  /// Wi-Fi'ye dönüldüğünde çağrılır.
  void resume() {
    _paused = false;
    debugPrint('[Prefetch] Resumed (Wi-Fi)');
    _publishPrefetchHealthIfNeeded(force: true);
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
      _trackQueueDispatchLatency(job.docID);
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
            .get(Uri.parse(url), headers: _cdnHeaders)
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
            .get(Uri.parse(url), headers: _cdnHeaders)
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

      // İZLENMEYEN: sadece ilk 2 segment hazır tutulur.
      // İZLENEN: sadece bir sonraki segment indirilir.
      final Iterable<String> toDownload;
      if (_mobileSeedMode && isUnwatched) {
        final mobileOrdered = _pickMobileSeedSegments(
          docID: job.docID,
          segmentUris: segmentUris,
          variantDir: variantDir,
          cacheManager: cacheManager,
        );
        final int mobileCap =
            job.maxSegments > 0 ? job.maxSegments : mobileOrdered.length;
        toDownload = mobileOrdered.take(mobileCap);
      } else if (isUnwatched) {
        final readyCap =
            job.maxSegments > 0 ? job.maxSegments : _targetReadySegments;
        toDownload = uncached.take(readyCap);
      } else {
        final preferred = _pickWatchedPrioritySegments(
          docID: job.docID,
          segmentUris: segmentUris,
          variantDir: variantDir,
          cacheManager: cacheManager,
          watchProgress: watchedProgress,
        );
        toDownload = preferred.take(1);
      }

      for (final segUri in toDownload) {
        if (_paused) break;

        final segmentCdnUrl =
            '$_cdnOrigin/${variantDir.startsWith('/') ? variantDir.substring(1) : variantDir}$segUri';
        final segmentKey =
            '${variantDir.replaceFirst('Posts/${job.docID}/hls/', '')}$segUri';

        _activeDownloads++;
        _resetWatchdog();
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
    final policy = PlaybackPolicyEngine.maybeFind();
    if (policy == null) return false;
    return policy
        .snapshot(
          visibleReadyCount: _lastFeedReadyCount,
          visibleWindowCount: _lastFeedWindowCount,
        )
        .enableMobileSeedMode;
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
    // İlk 2 segment başlangıçta hazır.
    // Oynatma sırasında sadece bir sonraki segment hazırlanır.
    // (1-2 aralığında 3. segmente geçilir.)
    final baseTarget = watchedSeg <= 2 ? 3 : watchedSeg + 1;

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
    _resetWatchdog();

    if (result.success) {
      final bytes = result.bytes!;
      _trackDownloadBytes(bytes.length);
      final cacheManager = _getCacheManager();
      if (cacheManager != null) {
        unawaited(
          cacheManager
              .writeSegment(
                result.docID,
                result.segmentKey,
                bytes,
              )
              .then((_) => _updateFeedReadyRatio())
              .catchError((_) {}),
        );
      }
    } else {
      debugPrint(
          '[Prefetch] Download failed: ${result.docID}/${result.segmentKey} — ${result.error}');
    }

    _publishPrefetchHealthIfNeeded();

    // Kuyrukta daha var mı?
    _processQueue();
  }

  void _trackQueueDispatchLatency(String docID) {
    final enqueuedAt = _jobEnqueuedAt.remove(docID);
    if (enqueuedAt == null) return;
    final latencyMs = DateTime.now().difference(enqueuedAt).inMilliseconds;
    if (latencyMs < 0) return;
    _queueLatencySamples += 1;
    _avgQueueDispatchLatencyMs +=
        (latencyMs - _avgQueueDispatchLatencyMs) / _queueLatencySamples;
  }

  void _updateFeedReadyRatio() {
    final cacheManager = _getCacheManager();
    if (cacheManager == null) {
      _lastFeedReadyCount = 0;
      _lastFeedWindowCount = 0;
      _lastFeedReadyRatio = 0.0;
      return;
    }
    if (_lastFeedDocIDs.isEmpty) {
      _lastFeedReadyCount = 0;
      _lastFeedWindowCount = 0;
      _lastFeedReadyRatio = 0.0;
      return;
    }

    final safeCurrent =
        _lastFeedCurrentIndex.clamp(0, _lastFeedDocIDs.length - 1);
    final aroundStart = (safeCurrent - 5).clamp(0, _lastFeedDocIDs.length - 1);
    final aroundEnd = (safeCurrent + 5).clamp(0, _lastFeedDocIDs.length - 1);
    final initialEnd = (safeCurrent + _feedFullWindow - 1).clamp(
      0,
      _lastFeedDocIDs.length - 1,
    );

    final targetIndices = <int>{};
    for (int i = safeCurrent; i <= initialEnd; i++) {
      targetIndices.add(i);
    }
    for (int i = aroundStart; i <= aroundEnd; i++) {
      targetIndices.add(i);
    }

    int ready = 0;
    for (final idx in targetIndices) {
      final docID = _lastFeedDocIDs[idx];
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.cachedSegmentCount >= _targetReadySegments) {
        ready++;
      }
    }

    _lastFeedReadyCount = ready;
    _lastFeedWindowCount = targetIndices.length;
    _lastFeedReadyRatio =
        targetIndices.isEmpty ? 0.0 : (ready / targetIndices.length);
    _publishPrefetchHealthIfNeeded();
  }

  /// Watchdog: 30sn boyunca hiç download result gelmezse _activeDownloads sıkışmıştır.
  /// Worker'ı yeniden başlat ve kuyruğu devam ettir.
  void _resetWatchdog() {
    _watchdogTimer?.cancel();
    if (_activeDownloads > 0) {
      _watchdogTimer = Timer(const Duration(seconds: 30), () {
        if (_activeDownloads > 0) {
          debugPrint(
              '[Prefetch] Watchdog: $_activeDownloads stuck downloads, resetting worker');
          _activeDownloads = 0;
          _workerSub?.cancel();
          _workerSub = null;
          _worker?.stop();
          _worker = null;
          _processQueue();
        }
      });
    }
  }

  void _trackDownloadBytes(int bytes) {
    if (bytes <= 0) return;
    _pendingDownloadBytes += bytes;

    const int oneMb = 1024 * 1024;
    final int downloadMb = _pendingDownloadBytes ~/ oneMb;
    if (downloadMb <= 0) return;

    _pendingDownloadBytes -= downloadMb * oneMb;

    final network = NetworkAwarenessService.maybeFind();
    if (network == null) return;
    unawaited(network.trackDataUsage(uploadMB: 0, downloadMB: downloadMb));
  }

  void _publishPrefetchHealthIfNeeded({bool force = false}) {
    final playbackKpi = PlaybackKpiService.maybeFind();
    if (playbackKpi == null) return;

    final readyBucket = (_lastFeedReadyRatio * 10).floor().clamp(0, 10);
    final latencyBucket = (_avgQueueDispatchLatencyMs / 250).floor().clamp(
          0,
          20,
        );
    final signature = [
      _paused ? 'paused' : 'active',
      _mobileSeedMode ? 'mobile_seed' : 'standard',
      'q$_queue.length',
      'a$_activeDownloads',
      'r$readyBucket',
      'l$latencyBucket',
    ].join('|');

    if (!force && signature == _lastPrefetchHealthSignature) {
      return;
    }
    _lastPrefetchHealthSignature = signature;

    playbackKpi.track(
      PlaybackKpiEventType.prefetchHealth,
      {
        'paused': _paused,
        'mobileSeedMode': _mobileSeedMode,
        'queueSize': _queue.length,
        'activeDownloads': _activeDownloads,
        'maxConcurrent': _maxConcurrent,
        'feedReadyRatio': _lastFeedReadyRatio,
        'feedReadyCount': _lastFeedReadyCount,
        'feedWindowCount': _lastFeedWindowCount,
        'avgQueueDispatchLatencyMs': _avgQueueDispatchLatencyMs,
      },
    );
  }

  // ──────────────────────────── Helpers ────────────────────────────

  SegmentCacheManager? _getCacheManager() => SegmentCacheManager.maybeFind();

  @override
  void onClose() {
    _watchdogTimer?.cancel();
    _workerSub?.cancel();
    _worker?.stop();
    if (_pendingDownloadBytes > 0) {
      final int downloadMb = (_pendingDownloadBytes / (1024 * 1024)).ceil();
      final network = NetworkAwarenessService.maybeFind();
      if (network != null) {
        unawaited(network.trackDataUsage(uploadMB: 0, downloadMB: downloadMb));
      }
      _pendingDownloadBytes = 0;
    }
    _httpClient.close();
    super.onClose();
  }
}

class _PrefetchJob {
  final String docID;
  final int maxSegments; // Bu job için indirilecek maksimum segment.
  final int priority; // düşük = önce
  final double sortScore;

  _PrefetchJob({
    required this.docID,
    required this.maxSegments,
    required this.priority,
    required this.sortScore,
  });
}
