part of 'prefetch_scheduler.dart';

extension PrefetchSchedulerWorkerPart on PrefetchScheduler {
  bool _isBankDocId(String docID) => _lastFeedBankDocIDs.contains(docID);

  bool _isCurrentPriorityDoc(String docID) {
    if (_lastPriorityDocIDs.isEmpty) return false;
    final safeCurrent = _lastPriorityCurrentIndex.clamp(
      0,
      _lastPriorityDocIDs.length - 1,
    );
    return _lastPriorityDocIDs[safeCurrent] == docID;
  }

  int _followUpPriorityForJob(_PrefetchJob job) {
    final targetIndex = _lastPriorityDocIDs.indexOf(job.docID);
    if (targetIndex < 0) {
      return job.priority + 1;
    }
    if (isPriorityWindowTargetIndex(
      currentIndex: _lastPriorityCurrentIndex,
      targetIndex: targetIndex,
    )) {
      return job.priority;
    }
    return job.priority + 1;
  }

  _PrefetchJob _buildFollowUpJob(_PrefetchJob job) {
    return _PrefetchJob(
      job.docID,
      job.maxSegments,
      _followUpPriorityForJob(job),
      -1000000.0,
    );
  }

  void _deferFollowUpJob(_PrefetchJob job) {
    _pendingFollowUpJobs[job.docID] = _buildFollowUpJob(job);
  }

  void _clearFollowUpJob(String docID) {
    _pendingFollowUpJobs.remove(docID);
  }

  void _requeueDeferredJobIfNeeded(
    String docID,
    SegmentCacheManager cacheManager,
  ) {
    final followUpJob = _pendingFollowUpJobs.remove(docID);
    if (followUpJob == null) return;
    final entry = cacheManager.getEntry(docID);
    final cachedSegments = entry?.cachedSegmentCount ?? 0;
    final totalSegments = entry?.totalSegmentCount ?? 0;
    if (cachedSegments >= followUpJob.maxSegments) return;
    if (totalSegments > 0 && cachedSegments >= totalSegments) return;
    _requeueJob(followUpJob);
  }

  void _requeueJob(_PrefetchJob job) {
    _queue.removeWhere((queuedJob) => queuedJob.docID == job.docID);
    _queue.add(job);
    _jobEnqueuedAt[job.docID] = DateTime.now();
    _queue.sort(_compareJobs);
  }

  void pause() {
    _paused = true;
    _queue.clear();
    _pendingFollowUpJobs.clear();
    _jobEnqueuedAt.clear();
    _activeDocRefCounts.clear();
    _activeBankDownloads = 0;
    _activeBankDocIDs.clear();

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
    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;
    if (_hasReachedWifiQuotaFillTarget(cacheManager)) {
      _publishPrefetchHealthIfNeeded(force: true);
      return;
    }
    if (_activeDownloads == 0 &&
        (_queue.isEmpty ||
            (_queue.length + _pendingFollowUpJobs.length) <=
                _prefetchSchedulerQuotaFillLowWatermark)) {
      await _ensureWifiQuotaFillPlan();
    }
    _ensureFeedBankBatchQueuedIfNeeded(cacheManager);
    if (_paused || _queue.isEmpty) return;
    if (_activeDownloads >= _maxConcurrent) return;

    if (_worker == null) {
      _worker = DownloadWorker();
      await _worker!.start();
      _workerSub = _worker!.results.listen(_onDownloadResult);
    }

    while (_queue.isNotEmpty && _activeDownloads < _maxConcurrent && !_paused) {
      if (_hasReachedWifiQuotaFillTarget(cacheManager)) {
        _publishPrefetchHealthIfNeeded(force: true);
        return;
      }
      final job = _takeNextQueuedJob();
      _trackQueueDispatchLatency(job.docID);
      await _processJob(job);
    }
  }

  _PrefetchJob _takeNextQueuedJob() {
    if (!_isOnWiFi || _activeBankDownloads > 0 || _queue.length <= 1) {
      return _queue.removeAt(0);
    }

    if (_activeDownloads <= 0) {
      return _queue.removeAt(0);
    }

    final bankIndex = _queue.indexWhere((job) => _isBankDocId(job.docID));
    if (bankIndex <= 0) {
      return _queue.removeAt(0);
    }
    return _queue.removeAt(bankIndex);
  }

  Future<void> _processJob(_PrefetchJob job) async {
    if (!CacheNetworkPolicy.canPrefetch && !_mobileSeedMode) {
      pause();
      return;
    }

    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;

    try {
      final probe = ensureHlsDataUsageProbe();
      final masterPath = _resolveMasterPlaylistPath(job.docID, cacheManager);
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
        final url = '$_prefetchSchedulerCdnOrigin/$masterPath';
        final response = await _httpClient
            .get(Uri.parse(url), headers: _prefetchSchedulerCdnHeaders)
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
        final url = '$_prefetchSchedulerCdnOrigin/$variantPath';
        final response = await _httpClient
            .get(Uri.parse(url), headers: _prefetchSchedulerCdnHeaders)
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
      final hlsRoot = _resolveHlsRoot(masterPath);

      cacheManager.updateEntryMeta(
        job.docID,
        '$_prefetchSchedulerCdnOrigin/$masterPath',
        segmentUris.length,
      );

      final variantDir =
          variantPath.substring(0, variantPath.lastIndexOf('/') + 1);
      final uncached = <String>[];
      for (final uri in segmentUris) {
        final segmentKey = '$variantDir$uri'.replaceFirst(hlsRoot, '');
        if (cacheManager.getSegmentFile(job.docID, segmentKey) == null) {
          uncached.add(uri);
        }
      }

      final entryForPolicy = cacheManager.getEntry(job.docID);
      final watchedProgress = entryForPolicy?.watchProgress ?? 0.0;
      final isUnwatched = watchedProgress <= 0.01;
      final desiredReadySegments = job.maxSegments > 0
          ? job.maxSegments
          : _prefetchSchedulerTargetReadySegments;
      final quotaFillMode = shouldUsePrefetchQuotaFillMode(
        isOnWiFi: _isOnWiFi,
        mobileSeedMode: _mobileSeedMode,
        watchProgress: watchedProgress,
      );
      final startupBurstMode = shouldUseStartupBurstPrefetch(
        isFocusedDoc: _focusedDocID == job.docID,
        isCurrentDoc: _isCurrentPriorityDoc(job.docID),
        watchProgress: watchedProgress,
        cachedSegmentCount: entryForPolicy?.cachedSegmentCount ?? 0,
        desiredReadySegments: desiredReadySegments,
        totalSegments: segmentUris.length,
      );

      final Iterable<String> toDownload;
      if (quotaFillMode) {
        toDownload = _pickQuotaFillPrioritySegments(
          docID: job.docID,
          segmentUris: segmentUris,
          variantDir: variantDir,
          cacheManager: cacheManager,
          desiredReadySegments: desiredReadySegments,
        );
      } else if (_mobileSeedMode && isUnwatched) {
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
        toDownload = uncached.take(desiredReadySegments);
      } else {
        final preferred = _pickWatchedPrioritySegments(
          docID: job.docID,
          segmentUris: segmentUris,
          variantDir: variantDir,
          cacheManager: cacheManager,
          watchProgress: watchedProgress,
          desiredReadySegments: job.maxSegments > 0 ? job.maxSegments : null,
        );
        toDownload = preferred.take(1);
      }

      final orderedDownloads = toDownload.toList(growable: false);
      if (orderedDownloads.isEmpty) return;

      final availableSlots = (_maxConcurrent - _activeDownloads).clamp(
        0,
        orderedDownloads.length,
      );
      if (availableSlots <= 0) {
        _requeueJob(job);
        return;
      }

      final seedNextSegmentLater = !startupBurstMode &&
          !quotaFillMode &&
          (isUnwatched && !_mobileSeedMode);
      final dispatchLimit = seedNextSegmentLater
          ? 1
          : quotaFillMode
              ? availableSlots < _prefetchSchedulerQuotaFillBurstSegments
                  ? availableSlots
                  : _prefetchSchedulerQuotaFillBurstSegments
          : startupBurstMode
              ? availableSlots < desiredReadySegments
                  ? availableSlots
                  : desiredReadySegments
              : availableSlots;
      final dispatchNow =
          orderedDownloads.take(dispatchLimit).toList(growable: false);
      final hasRemaining = orderedDownloads.length > dispatchNow.length;

      for (final segUri in dispatchNow) {
        if (_paused) break;
        if (_hasReachedWifiQuotaFillTarget(cacheManager)) {
          _publishPrefetchHealthIfNeeded(force: true);
          break;
        }

        final segmentCdnUrl =
            '$_prefetchSchedulerCdnOrigin/${variantDir.startsWith('/') ? variantDir.substring(1) : variantDir}$segUri';
        final segmentKey = '${variantDir.replaceFirst(hlsRoot, '')}$segUri';

        _activeDocRefCounts.update(
          job.docID,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        if (_isBankDocId(job.docID) && _activeBankDocIDs.add(job.docID)) {
          _activeBankDownloads++;
        }
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

      if (hasRemaining &&
          !_paused &&
          !_hasReachedWifiQuotaFillTarget(cacheManager)) {
        if (seedNextSegmentLater) {
          _deferFollowUpJob(job);
        } else {
          _requeueJob(job);
        }
      }
    } catch (e, stackTrace) {
      _clearFollowUpJob(job.docID);
      debugPrint('[Prefetch] Job failed for ${job.docID}: $e');
      debugPrintStack(
        label: '[Prefetch] Job failed stack for ${job.docID}',
        stackTrace: stackTrace,
      );
    }
  }

  String _resolveMasterPlaylistPath(
    String docId,
    SegmentCacheManager cacheManager,
  ) {
    final entry = cacheManager.getEntry(docId);
    final seededPath =
        hlsRelativePathFromUrlOrPath(entry?.masterPlaylistUrl ?? '');
    if (seededPath != null && seededPath.isNotEmpty) {
      return seededPath;
    }
    return 'Posts/$docId/hls/master.m3u8';
  }

  String _resolveHlsRoot(String masterPath) {
    final hlsIndex = masterPath.indexOf('/hls/');
    if (hlsIndex < 0) {
      return masterPath.substring(0, masterPath.lastIndexOf('/') + 1);
    }
    return masterPath.substring(0, hlsIndex + '/hls/'.length);
  }

  void _onDownloadResult(DownloadResult result) {
    _activeDownloads = (_activeDownloads - 1).clamp(0, _maxConcurrent * 2);
    final remainingActiveRefs = (_activeDocRefCounts[result.docID] ?? 0) - 1;
    if (remainingActiveRefs > 0) {
      _activeDocRefCounts[result.docID] = remainingActiveRefs;
    } else {
      _activeDocRefCounts.remove(result.docID);
    }
    if (_activeBankDocIDs.remove(result.docID)) {
      _activeBankDownloads =
          (_activeBankDownloads - 1).clamp(0, _maxConcurrent);
    }
    _resetWatchdog();

    if (result.success) {
      final bytes = result.bytes!;
      _trackDownloadBytes(bytes.length);
      ensureHlsDataUsageProbe().recordSegmentTransfer(
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
              .then((_) {
            _updateFeedReadyRatio();
            _publishPrefetchHealthIfNeeded();
            _requeueDeferredJobIfNeeded(result.docID, cacheManager);
            _processQueue();
          }).catchError((_) {
            _clearFollowUpJob(result.docID);
            _publishPrefetchHealthIfNeeded();
            _processQueue();
          }),
        );
        return;
      }
    } else {
      _clearFollowUpJob(result.docID);
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
      final readySegments = _resolvedReadySegmentTarget(
        docID: docID,
        cacheManager: cacheManager,
      );
      if (entry != null && entry.cachedSegmentCount >= readySegments) {
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
          _activeDocRefCounts.clear();
          _activeBankDownloads = 0;
          _activeBankDocIDs.clear();
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
    final playbackKpi = maybeFindPlaybackKpiService();
    if (playbackKpi == null) return;
    final cacheManager = _getCacheManager();
    final quotaReached =
        cacheManager != null && _hasReachedWifiQuotaFillTarget(cacheManager);
    final quotaBucket = cacheManager == null
        ? 0
        : (_wifiQuotaFillRatio(cacheManager) * 10).floor().clamp(0, 10);

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
      'quota${quotaReached ? 'stop' : 'ok'}',
      'qb$quotaBucket',
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
        'wifiQuotaFillRatio':
            cacheManager == null ? 0.0 : _wifiQuotaFillRatio(cacheManager),
        'wifiQuotaFillTargetBytes': _wifiQuotaFillTargetBytes,
        'wifiQuotaFillTargetReached': quotaReached,
      },
    );
  }
}
