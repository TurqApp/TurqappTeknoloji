part of 'prefetch_scheduler.dart';

extension PrefetchSchedulerWorkerPart on PrefetchScheduler {
  void pause() {
    _paused = true;
    _queue.clear();
    _jobEnqueuedAt.clear();

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

  void resume() {
    _paused = false;
    debugPrint('[Prefetch] Resumed (Wi-Fi)');
    _publishPrefetchHealthIfNeeded(force: true);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (!CacheNetworkPolicy.canPrefetch && !_mobileSeedMode) {
      pause();
      return;
    }
    if (_paused || _queue.isEmpty) return;
    if (_activeDownloads >= _maxConcurrent) return;

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
      final probe = HlsDataUsageProbe.ensure();
      final masterPath = 'Posts/${job.docID}/hls/master.m3u8';
      String? masterContent;

      final cachedMaster = cacheManager.getPlaylistFile(masterPath);
      if (cachedMaster != null) {
        masterContent = await cachedMaster.readAsString();
        probe.recordMasterPlaylist(
          docId: job.docID,
          path: '/$masterPath',
          content: masterContent,
          source: HlsTrafficSource.prefetch,
          cacheHit: true,
        );
      } else {
        final url = '${PrefetchScheduler._cdnOrigin}/$masterPath';
        final response = await _httpClient
            .get(Uri.parse(url), headers: PrefetchScheduler._cdnHeaders)
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          masterContent = response.body;
          probe.recordMasterPlaylist(
            docId: job.docID,
            path: '/$masterPath',
            content: masterContent,
            source: HlsTrafficSource.prefetch,
            cacheHit: false,
          );
          await cacheManager.writePlaylist(masterPath, masterContent);
        }
      }

      if (masterContent == null) return;

      final variants = M3U8Parser.parseVariants(masterContent);
      final variant = M3U8Parser.bestVariant(variants);
      if (variant == null) return;

      final masterDir =
          masterPath.substring(0, masterPath.lastIndexOf('/') + 1);
      final variantPath = '$masterDir${variant.uri}';
      String? variantContent;

      final cachedVariant = cacheManager.getPlaylistFile(variantPath);
      if (cachedVariant != null) {
        variantContent = await cachedVariant.readAsString();
        probe.recordVariantPlaylist(
          docId: job.docID,
          path: '/$variantPath',
          content: variantContent,
          source: HlsTrafficSource.prefetch,
          cacheHit: true,
        );
      } else {
        final url = '${PrefetchScheduler._cdnOrigin}/$variantPath';
        final response = await _httpClient
            .get(Uri.parse(url), headers: PrefetchScheduler._cdnHeaders)
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          variantContent = response.body;
          probe.recordVariantPlaylist(
            docId: job.docID,
            path: '/$variantPath',
            content: variantContent,
            source: HlsTrafficSource.prefetch,
            cacheHit: false,
          );
          await cacheManager.writePlaylist(variantPath, variantContent);
        }
      }

      if (variantContent == null) return;

      final segmentUris = M3U8Parser.segmentUris(variantContent);

      cacheManager.updateEntryMeta(
        job.docID,
        '${PrefetchScheduler._cdnOrigin}/$masterPath',
        segmentUris.length,
      );

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
        final readyCap = job.maxSegments > 0
            ? job.maxSegments
            : PrefetchScheduler._targetReadySegments;
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
            '${PrefetchScheduler._cdnOrigin}/${variantDir.startsWith('/') ? variantDir.substring(1) : variantDir}$segUri';
        final segmentKey =
            '${variantDir.replaceFirst('Posts/${job.docID}/hls/', '')}$segUri';

        _activeDownloads++;
        _resetWatchdog();
        probe.recordSegmentStart(
          docId: job.docID,
          segmentKey: segmentKey,
          source: HlsTrafficSource.prefetch,
        );
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
    _resetWatchdog();

    if (result.success) {
      final bytes = result.bytes!;
      _trackDownloadBytes(bytes.length);
      HlsDataUsageProbe.ensure().recordSegmentTransfer(
        docId: result.docID,
        segmentKey: result.segmentKey,
        bytes: bytes.length,
        source: HlsTrafficSource.prefetch,
        cacheHit: false,
      );
      final cacheManager = _getCacheManager();
      if (cacheManager != null) {
        unawaited(
          cacheManager
              .writeSegment(result.docID, result.segmentKey, bytes)
              .then((_) => _updateFeedReadyRatio())
              .catchError((_) {}),
        );
      }
    } else {
      debugPrint(
        '[Prefetch] Download failed: ${result.docID}/${result.segmentKey} — ${result.error}',
      );
    }

    _publishPrefetchHealthIfNeeded();
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
      if (entry != null &&
          entry.cachedSegmentCount >= PrefetchScheduler._targetReadySegments) {
        ready++;
      }
    }

    _lastFeedReadyCount = ready;
    _lastFeedWindowCount = targetIndices.length;
    _lastFeedReadyRatio =
        targetIndices.isEmpty ? 0.0 : (ready / targetIndices.length);
    _publishPrefetchHealthIfNeeded();
  }

  void _resetWatchdog() {
    _watchdogTimer?.cancel();
    if (_activeDownloads > 0) {
      _watchdogTimer = Timer(const Duration(seconds: 30), () {
        if (_activeDownloads > 0) {
          debugPrint(
            '[Prefetch] Watchdog: $_activeDownloads stuck downloads, resetting worker',
          );
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
}
