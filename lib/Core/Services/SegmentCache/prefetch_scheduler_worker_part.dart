part of 'prefetch_scheduler.dart';

extension PrefetchSchedulerWorkerPart on PrefetchScheduler {
  String _segmentRequestKey(String docID, String segmentKey) =>
      '$docID|$segmentKey';

  String _nextSegmentRequestID(String docID, String segmentKey) =>
      '${DateTime.now().microsecondsSinceEpoch}|$docID|$segmentKey';

  String? _prefetchSourceForDoc(String docID) {
    final activeSource = _activeDocSources[docID];
    if (activeSource != null && activeSource.isNotEmpty) {
      return activeSource;
    }
    final pendingSource = _pendingFollowUpJobs[docID]?.source;
    if (pendingSource != null && pendingSource.isNotEmpty) {
      return pendingSource;
    }
    for (final job in _queue) {
      if (job.docID == docID && job.source.isNotEmpty) {
        return job.source;
      }
    }
    return null;
  }

  bool _shouldAbortStalePrefetchDoc(String docID) {
    final source = _prefetchSourceForDoc(docID);
    if (source == null) {
      return false;
    }
    if (source == 'quota') {
      return !_shouldAllowBackgroundQuotaFill;
    }
    final tierInfo = classifyTransferDoc(docID);
    return tierInfo == null || tierInfo['allowedSegmentWarm'] != true;
  }

  void _abortStalePrefetchActivity({
    required String reason,
  }) {
    final staleQueuedDocIds = _queue
        .where((job) => _shouldAbortStalePrefetchDoc(job.docID))
        .map((job) => job.docID)
        .toSet();
    final stalePendingDocIds =
        _pendingFollowUpJobs.keys.where(_shouldAbortStalePrefetchDoc).toSet();
    final staleActiveDocIds =
        _activeDocRefCounts.keys.where(_shouldAbortStalePrefetchDoc).toSet();
    if (staleQueuedDocIds.isEmpty &&
        stalePendingDocIds.isEmpty &&
        staleActiveDocIds.isEmpty) {
      return;
    }

    _queue.removeWhere((job) => staleQueuedDocIds.contains(job.docID));
    for (final docID in stalePendingDocIds) {
      _pendingFollowUpJobs.remove(docID);
    }
    for (final docID in <String>{
      ...staleQueuedDocIds,
      ...stalePendingDocIds,
    }) {
      _jobEnqueuedAt.remove(docID);
      _activeDocSources.remove(docID);
      _activeBankDocIDs.remove(docID);
    }
    for (final docID in staleActiveDocIds) {
      _jobEnqueuedAt.remove(docID);
      _activeBankDocIDs.remove(docID);
    }

    if (staleActiveDocIds.isNotEmpty && _activeDownloads > 0) {
      _workerSub?.cancel();
      _workerSub = null;
      _worker?.stop();
      _worker = null;
      _activeDownloads = 0;
      _activeDocRefCounts.clear();
      _activeSegmentRequestIDs.clear();
      _activeSegmentOwnerInfo.clear();
      _activeSegmentTierInfo.clear();
      _activeBankDownloads = 0;
      _activeBankDocIDs.clear();
    } else {
      for (final docID in staleActiveDocIds) {
        _activeDocRefCounts.remove(docID);
        _activeDocSources.remove(docID);
        final requestKeysToClear = _activeSegmentRequestIDs.entries
            .where((entry) => entry.key.startsWith('$docID|'))
            .map((entry) => entry.key)
            .toList(growable: false);
        for (final requestKey in requestKeysToClear) {
          _activeSegmentRequestIDs.remove(requestKey);
          _activeSegmentOwnerInfo.remove(requestKey);
          _activeSegmentTierInfo.remove(requestKey);
        }
      }
    }

    debugPrint(
      '[Prefetch] Aborted stale prefetch reason=$reason '
      'queued=${staleQueuedDocIds.join(",")} '
      'pending=${stalePendingDocIds.join(",")} '
      'active=${staleActiveDocIds.join(",")}',
    );
    _publishPrefetchHealthIfNeeded(force: true);
  }

  int _effectiveMaxConcurrent() {
    if (_hasActiveFeedPlaybackWindow) {
      return _maxConcurrent < 2 ? _maxConcurrent : 2;
    }
    if (_hasAnyActivePlaybackFocus) {
      return _maxConcurrent > 1 ? 1 : _maxConcurrent;
    }
    if (_lastFeedWindowCount <= 0) {
      return _maxConcurrent > 1 ? 1 : _maxConcurrent;
    }
    final startupReadyThreshold = ReadBudgetRegistry.feedReadyForNavCount > 5
        ? ReadBudgetRegistry.feedReadyForNavCount
        : 5;
    if (_lastFeedReadyCount < startupReadyThreshold) {
      return _maxConcurrent > 1 ? 1 : _maxConcurrent;
    }

    final delayedRampThreshold = startupReadyThreshold + 5;
    final startupRampThreshold =
        delayedRampThreshold > 10 ? delayedRampThreshold : 10;
    if (_lastFeedReadyCount < startupRampThreshold) {
      return _maxConcurrent < 2 ? _maxConcurrent : 2;
    }

    return _maxConcurrent;
  }

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
      source: job.source,
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
    final liveReadySegments = _resolveLiveFeedReadySegmentsForDoc(
      docID,
      cacheManager,
    );
    if (liveReadySegments != null && liveReadySegments <= 0) {
      return;
    }
    final targetReadySegments = liveReadySegments ?? followUpJob.maxSegments;
    final entry = cacheManager.getEntry(docID);
    final cachedSegments = entry?.cachedSegmentCount ?? 0;
    final totalSegments = entry?.totalSegmentCount ?? 0;
    if (cachedSegments >= targetReadySegments) return;
    if (totalSegments > 0 && cachedSegments >= totalSegments) return;
    _requeueJob(
      _PrefetchJob(
        docID,
        targetReadySegments,
        _followUpPriorityForJob(followUpJob),
        -1000000.0,
        source: followUpJob.source,
      ),
    );
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
    _activeDocSources.clear();
    _activeSegmentRequestIDs.clear();
    _activeSegmentOwnerInfo.clear();
    _activeSegmentTierInfo.clear();
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
    if (!_isOnWiFi || !CacheNetworkPolicy.canPrefetch) {
      debugPrint(
        '[ShortQuotaFill] status=skip reason=network_gate wifi=$_isOnWiFi '
        'canPrefetch=${CacheNetworkPolicy.canPrefetch}',
      );
      pause();
      return;
    }
    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;
    if (_hasReachedWifiQuotaFillTarget(cacheManager)) {
      debugPrint(
        '[ShortQuotaFill] status=skip reason=target_reached '
        'usageBytes=${cacheManager.totalTrackedUsageBytes} '
        'targetBytes=$_wifiQuotaFillTargetBytes',
      );
      _publishPrefetchHealthIfNeeded(force: true);
      return;
    }
    var currentBacklog = _queue.length +
        _pendingFollowUpJobs.length +
        _activeDocRefCounts.length;
    if (!_shouldAllowBackgroundQuotaFill) {
      _abortStalePrefetchActivity(reason: 'quota_background_gate');
      currentBacklog = _queue.length +
          _pendingFollowUpJobs.length +
          _activeDocRefCounts.length;
    }
    debugPrint(
      '[ShortQuotaFill] status=worker_check enabled=$_automaticQuotaFillEnabled '
      'allow=$_shouldAllowBackgroundQuotaFill backlog=$currentBacklog '
      'activeDownloads=$_activeDownloads activeFeed=$_hasActiveFeedPlaybackWindow '
      'activeShort=$_hasActiveShortPlaybackWindow '
      'activeProfile=$_hasActiveProfilePlaybackWindow',
    );
    if (_automaticQuotaFillEnabled &&
        _shouldAllowBackgroundQuotaFill &&
        (_queue.isEmpty ||
            (_queue.length + _pendingFollowUpJobs.length) <=
                _prefetchSchedulerQuotaFillLowWatermark)) {
      await _ensureWifiQuotaFillPlan();
    } else {
      final reason = !_automaticQuotaFillEnabled
          ? 'disabled'
          : (!_shouldAllowBackgroundQuotaFill
              ? 'background_gate'
              : 'backlog_high');
      debugPrint(
        '[ShortQuotaFill] status=skip reason=$reason '
        'queue=${_queue.length} pending=${_pendingFollowUpJobs.length} '
        'activeRefs=${_activeDocRefCounts.length}',
      );
    }
    final effectiveMaxConcurrent = _effectiveMaxConcurrent();
    if (_paused || _queue.isEmpty) return;
    if (_activeDownloads >= effectiveMaxConcurrent) return;

    if (_worker == null) {
      _worker = DownloadWorker();
      await _worker!.start();
      _workerSub = _worker!.results.listen(_onDownloadResult);
    }

    while (_queue.isNotEmpty &&
        _activeDownloads < effectiveMaxConcurrent &&
        !_paused) {
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
    if (!_isOnWiFi || !CacheNetworkPolicy.canPrefetch) {
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
      if (job.maxSegments <= 0) {
        _clearFollowUpJob(job.docID);
        return;
      }
      if (job.source == 'quota' && !_shouldAllowBackgroundQuotaFill) {
        _clearFollowUpJob(job.docID);
        _queue.removeWhere((queuedJob) => queuedJob.docID == job.docID);
        debugPrint(
          '[ShortQuotaFill] status=skip_job reason=active_playback doc=${job.docID}',
        );
        return;
      }
      final desiredReadySegments = job.maxSegments > 0
          ? job.maxSegments
          : _prefetchSchedulerTargetReadySegments;
      final quotaFillMode = job.source == 'quota' &&
          _shouldAllowBackgroundQuotaFill &&
          shouldUsePrefetchQuotaFillMode(
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

      final availableSlots =
          (_effectiveMaxConcurrent() - _activeDownloads).clamp(
        0,
        orderedDownloads.length,
      );
      if (availableSlots <= 0) {
        _requeueJob(job);
        return;
      }

      final shouldBurstVisibleShort = job.source == 'short' &&
          (_focusedDocID == job.docID || _isCurrentPriorityDoc(job.docID));
      final seedNextSegmentLater = !startupBurstMode &&
          !quotaFillMode &&
          !shouldBurstVisibleShort &&
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
        if (!quotaFillMode) {
          final tierInfo = classifyTransferDoc(job.docID);
          if (tierInfo != null && tierInfo['allowedSegmentWarm'] != true) {
            _clearFollowUpJob(job.docID);
            _queue.removeWhere((queuedJob) => queuedJob.docID == job.docID);
            break;
          }
        }
        if (_hasReachedWifiQuotaFillTarget(cacheManager)) {
          _publishPrefetchHealthIfNeeded(force: true);
          break;
        }

        final segmentCdnUrl =
            '$_prefetchSchedulerCdnOrigin/${variantDir.startsWith('/') ? variantDir.substring(1) : variantDir}$segUri';
        final segmentKey = '${variantDir.replaceFirst(hlsRoot, '')}$segUri';
        final requestKey = _segmentRequestKey(job.docID, segmentKey);
        final requestID = _nextSegmentRequestID(job.docID, segmentKey);

        _activeDocRefCounts.update(
          job.docID,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        _activeDocSources[job.docID] = job.source;
        _activeSegmentRequestIDs[requestKey] = requestID;
        if (_isBankDocId(job.docID) && _activeBankDocIDs.add(job.docID)) {
          _activeBankDownloads++;
        }
        _activeDownloads++;
        _resetWatchdog();
        final ownerInfoAtDispatch =
            describeTransferOwner(job.docID) ?? <String, dynamic>{};
        final tierInfoAtDispatch =
            classifyTransferDoc(job.docID) ?? <String, dynamic>{};
        _activeSegmentOwnerInfo[requestKey] =
            Map<String, dynamic>.from(ownerInfoAtDispatch);
        _activeSegmentTierInfo[requestKey] =
            Map<String, dynamic>.from(tierInfoAtDispatch);
        probe.recordSegmentStart(
          docId: job.docID,
          segmentKey: segmentKey,
          source: HlsTrafficSource.prefetch,
          ownerInfo: ownerInfoAtDispatch,
          tierInfo: tierInfoAtDispatch,
        );
        _worker?.download(DownloadRequest(
          url: segmentCdnUrl,
          segmentKey: segmentKey,
          docID: job.docID,
          requestID: requestID,
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
    final requestKey = _segmentRequestKey(result.docID, result.segmentKey);
    final expectedRequestID = _activeSegmentRequestIDs[requestKey];
    if (expectedRequestID != null && expectedRequestID != result.requestID) {
      debugPrint(
        '[Prefetch] Dropped stale download result doc=${result.docID} '
        'segment=${result.segmentKey} expected=$expectedRequestID '
        'actual=${result.requestID}',
      );
      return;
    }
    _activeSegmentRequestIDs.remove(requestKey);
    final ownerInfoAtDispatch = _activeSegmentOwnerInfo.remove(requestKey);
    final tierInfoAtDispatch = _activeSegmentTierInfo.remove(requestKey);
    _activeDownloads = (_activeDownloads - 1).clamp(0, _maxConcurrent * 2);
    final remainingActiveRefs = (_activeDocRefCounts[result.docID] ?? 0) - 1;
    if (remainingActiveRefs > 0) {
      _activeDocRefCounts[result.docID] = remainingActiveRefs;
    } else {
      _activeDocRefCounts.remove(result.docID);
      _activeDocSources.remove(result.docID);
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
        ownerInfoOverride: ownerInfoAtDispatch,
        tierInfoOverride: tierInfoAtDispatch,
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

  int? _resolveLiveFeedReadySegmentsForDoc(
    String docID,
    SegmentCacheManager cacheManager,
  ) {
    if (_lastFeedDocIDs.isEmpty) return null;
    final targetIndex = _lastFeedDocIDs.indexOf(docID);
    if (targetIndex < 0) return null;
    final safeCurrent =
        _lastFeedCurrentIndex.clamp(0, _lastFeedDocIDs.length - 1);
    final readySegmentFallback = resolveFeedWindowReadySegments(
      currentIndex: safeCurrent,
      targetIndex: targetIndex,
    );
    return _resolvedReadySegmentTarget(
      docID: docID,
      cacheManager: cacheManager,
      fallback: readySegmentFallback,
    );
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
    final directionalWindow = resolveDirectionalFeedWindowCounts(
      previousIndex: _lastFeedPreviousIndex.clamp(
        0,
        _lastFeedDocIDs.length - 1,
      ),
      currentIndex: safeCurrent,
    );
    final behindStart = (safeCurrent - directionalWindow.behindCount)
        .clamp(0, _lastFeedDocIDs.length - 1);
    final aheadEnd = (safeCurrent + directionalWindow.aheadCount).clamp(
      0,
      _lastFeedDocIDs.length - 1,
    );

    final targetIndices = <int>{};
    for (int i = safeCurrent; i <= aheadEnd; i++) {
      targetIndices.add(i);
    }
    for (int i = behindStart; i < safeCurrent; i++) {
      targetIndices.add(i);
    }

    int ready = 0;
    for (final idx in targetIndices) {
      final docID = _lastFeedDocIDs[idx];
      final entry = cacheManager.getEntry(docID);
      final readySegmentFallback = resolveFeedWindowReadySegments(
        currentIndex: safeCurrent,
        targetIndex: idx,
      );
      final readySegments = _resolvedReadySegmentTarget(
        docID: docID,
        cacheManager: cacheManager,
        fallback: readySegmentFallback,
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
          _activeDocSources.clear();
          _activeSegmentRequestIDs.clear();
          _activeSegmentOwnerInfo.clear();
          _activeSegmentTierInfo.clear();
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
        'effectiveMaxConcurrent': _effectiveMaxConcurrent(),
        'automaticQuotaFillEnabled': _automaticQuotaFillEnabled,
        'hasActiveFeedPlaybackWindow': _hasActiveFeedPlaybackWindow,
        'hasActiveShortPlaybackWindow': _hasActiveShortPlaybackWindow,
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
