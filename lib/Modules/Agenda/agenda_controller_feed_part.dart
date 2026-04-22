part of 'agenda_controller.dart';

extension AgendaControllerFeedPart on AgendaController {
  static const int _startupThumbnailPrefetchInitialCount = 5;
  static const int _startupThumbnailPrefetchRadius = 5;
  String _feedPlaybackHandleKeyForDoc(String docId) => 'feed:${docId.trim()}';

  static const Duration _startupPlaybackLockDuration =
      Duration(milliseconds: StartupRouteGatePolicy.feedStartupPlaybackLockMs);
  static const Duration _iosStartupPlaybackLockDuration =
      Duration(milliseconds: 1200);
  static const Duration _androidStartupPlaybackPendingLockDuration = Duration(
    milliseconds:
        StartupRouteGatePolicy.androidFeedStartupPlaybackPendingLockMs,
  );
  static const Duration _androidStartupPlaybackGrace = Duration(
    milliseconds: StartupRouteGatePolicy.androidFeedStartupPlaybackGraceMs,
  );
  static const Duration _androidCurrentRecoveryGrace = Duration(
    milliseconds: StartupRouteGatePolicy.androidFeedCurrentRecoveryGraceMs,
  );
  static const Duration _androidCenteredGapPlaybackGrace = Duration(
    milliseconds: StartupRouteGatePolicy.androidFeedCenteredGapPlaybackGraceMs,
  );
  static const int _feedBoostPlayableCount =
      StartupPreloadPolicy.aheadFirstSegmentCount;
  static const int _feedPlaybackBoostLookAhead =
      StartupPreloadPolicy.aheadFirstSegmentCount;
  static const int _feedSplashWarmPlayableCount =
      StartupPreloadPolicy.startupWarmCount;
  static const List<int> _feedSecondSegmentAheadPlayableOffsets =
      StartupPreloadPolicy.secondSegmentAheadOffsets;
  static const int _feedPlannerGroupPostCount =
      FeedRenderBlockPlan.postsPerGroup;
  static const int _feedPlannerGroupsPerBlock =
      FeedRenderBlockPlan.groupsPerBlock;
  static const int _feedHotPrefetchGroupCount =
      FeedGrowthPolicy.hotPrefetchGroupCount;
  static const int _feedStartupWarmGroupCount =
      FeedGrowthPolicy.startupWarmGroupCount;

  int get _feedInitialPageFetchTriggerCount {
    return FeedGrowthPolicy.initialPageFetchTriggerCount(
      ReadBudgetRegistry.feedPageFetchLimit,
    );
  }

  void _resetFeedPageFetchTrigger() {
    _nextPageFetchTriggerCount = _feedInitialPageFetchTriggerCount;
  }

  void _advanceFeedPageFetchTrigger(int viewedCount) {
    _nextPageFetchTriggerCount = FeedGrowthPolicy.advancePageFetchTrigger(
      currentTriggerCount: _nextPageFetchTriggerCount,
      viewedCount: viewedCount,
      pageFetchLimit: ReadBudgetRegistry.feedPageFetchLimit,
    );
  }

  int _reachableFeedPageFetchTriggerCount() {
    if (agendaList.isEmpty) {
      return _feedInitialPageFetchTriggerCount;
    }
    final runwayTrigger = max(
      FeedGrowthPolicy.postsPerGroup,
      agendaList.length - FeedGrowthPolicy.growthRunwayPostCount,
    );
    return min(_nextPageFetchTriggerCount, runwayTrigger);
  }

  void _reconcileFeedPageFetchTriggerToCurrentRunway({
    required String reason,
  }) {
    final reconciledTrigger = _reachableFeedPageFetchTriggerCount();
    if (reconciledTrigger == _nextPageFetchTriggerCount) {
      return;
    }
    debugPrint(
      '[FeedFetchTrigger] source=reconcile '
      'reason=$reason currentCount=${agendaList.length} '
      'previousTrigger=$_nextPageFetchTriggerCount '
      'nextTrigger=$reconciledTrigger',
    );
    _nextPageFetchTriggerCount = reconciledTrigger;
  }

  void _maybeTriggerDeferredFeedGrowth({
    required String reason,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed ||
          agendaList.isEmpty ||
          isLoading.value ||
          !hasMore.value ||
          !scrollController.hasClients) {
        return;
      }
      _reconcileFeedPageFetchTriggerToCurrentRunway(
        reason: '${reason}_deferred_post_frame',
      );
      final centered = centeredIndex.value;
      final viewedCount =
          centered >= 0 && centered < agendaList.length ? centered + 1 : 0;
      if (viewedCount < _nextPageFetchTriggerCount) {
        return;
      }
      final triggerCount = _nextPageFetchTriggerCount;
      debugPrint(
        '[FeedFetchTrigger] source=deferred_post_apply '
        'reason=$reason viewedCount=$viewedCount '
        'currentCount=${agendaList.length} triggerCount=$triggerCount',
      );
      _advanceFeedPageFetchTrigger(viewedCount);
      fetchAgendaBigData(
        pageLimit: ReadBudgetRegistry.feedPageFetchLimit,
        trigger: 'deferred_post_apply',
      );
    });
  }

  void maybeTriggerFeedGrowthFromPromo({
    required String promoType,
    required int slotNumber,
    required int renderBlockIndex,
    required int renderGroupNumber,
    required double visibleFraction,
  }) {
    if (visibleFraction < 0.55) return;
    if (agendaList.isEmpty || !hasMore.value || isLoading.value) return;
    final viewedCount = FeedGrowthTriggerService.estimateViewedCountAtPromo(
      renderBlockIndex: renderBlockIndex,
      renderGroupNumber: renderGroupNumber,
    );
    final triggerCount = _nextPageFetchTriggerCount;
    if (!FeedGrowthTriggerService.shouldTriggerFallback(
      viewedCount: viewedCount,
      nextTriggerCount: triggerCount,
    )) {
      return;
    }
    debugPrint(
      '[FeedFetchTrigger] source=promo_near_end '
      'promoType=$promoType slotNumber=$slotNumber '
      'block=$renderBlockIndex group=$renderGroupNumber '
      'viewedCount=$viewedCount currentCount=${agendaList.length} '
      'pageLimit=${ReadBudgetRegistry.feedPageFetchLimit} '
      'triggerCount=$triggerCount visibleFraction=${visibleFraction.toStringAsFixed(2)}',
    );
    _advanceFeedPageFetchTrigger(viewedCount);
    recordQALabScrollEvent(
      surface: 'feed',
      phase: 'near_end',
      metadata: <String, dynamic>{
        'trigger': 'promo_near_end',
        'promoType': promoType,
        'slotNumber': slotNumber,
        'renderBlockIndex': renderBlockIndex,
        'renderGroupNumber': renderGroupNumber,
        'viewedCount': viewedCount,
        'count': agendaList.length,
        'nextTriggerCount': _nextPageFetchTriggerCount,
        'visibleFraction': visibleFraction,
      },
    );
    fetchAgendaBigData(
      pageLimit: ReadBudgetRegistry.feedPageFetchLimit,
      trigger: 'promo_near_end',
    );
    _maybeScheduleConnectedFeedReservoirForViewedCount(viewedCount);
  }

  bool _reclaimFeedPlaybackFromExternalOwner(
    VideoStateManager manager, {
    required String source,
  }) {
    final currentPlayingDocId = manager.currentPlayingDocID;
    if (!_hasExternalPlaybackOwner(currentPlayingDocId)) return false;
    recordQALabPlaybackDispatch(
      surface: 'feed',
      stage: 'feed_reclaim_external_owner',
      metadata: <String, dynamic>{
        'source': source,
        'currentPlayingDocID': currentPlayingDocId ?? '',
        'centeredIndex': centeredIndex.value,
        'isPrimaryFeedRouteVisible': isPrimaryFeedRouteVisible,
        'canClaimPlaybackNow': canClaimPlaybackNow,
      },
    );
    manager.exitExclusiveMode();
    manager.pauseAllVideos(force: true);
    return true;
  }

  Duration _playbackReassertDelayForAttempt(int attempt) {
    if (!GetPlatform.isAndroid) {
      return attempt == 0
          ? const Duration(milliseconds: 260)
          : const Duration(milliseconds: 140);
    }
    return attempt == 0
        ? const Duration(milliseconds: 180)
        : const Duration(milliseconds: 120);
  }

  bool _hasExternalPlaybackOwner(String? playbackHandleKey) {
    final key = playbackHandleKey?.trim() ?? '';
    if (key.isEmpty) return false;
    return !key.startsWith('feed:');
  }

  bool _shouldPreserveFeedPlaybackAcrossCenteredGap(
    VideoStateManager manager,
  ) {
    final currentPlayingDocId = manager.currentPlayingDocID?.trim() ?? '';
    if (!currentPlayingDocId.startsWith('feed:')) return false;
    return manager.shouldKeepAudiblePlayback(
      currentPlayingDocId,
      grace: GetPlatform.isAndroid
          ? _androidCenteredGapPlaybackGrace
          : const Duration(milliseconds: 480),
    );
  }

  ({int activeGroupIndex, int activeBlockIndex, int activeGroupInBlock})
      _resolveFeedWarmIdentity(int centered) {
    final safeCentered =
        centered >= 0 && centered < agendaList.length ? centered : 0;
    final activeGroupIndex = safeCentered ~/ _feedPlannerGroupPostCount;
    return (
      activeGroupIndex: activeGroupIndex,
      activeBlockIndex: activeGroupIndex ~/ _feedPlannerGroupsPerBlock,
      activeGroupInBlock: activeGroupIndex % _feedPlannerGroupsPerBlock,
    );
  }

  ({int start, int endExclusive}) _resolveFeedWarmPostRange({
    required int startGroupIndex,
    required int hotGroupCount,
  }) {
    if (agendaList.isEmpty || hotGroupCount <= 0) {
      return (start: 0, endExclusive: 0);
    }
    final start = startGroupIndex * _feedPlannerGroupPostCount;
    final endExclusive = min(
      agendaList.length,
      start + (_feedPlannerGroupPostCount * hotGroupCount),
    );
    return (start: start, endExclusive: endExclusive);
  }

  void _recordFeedWarmSchedulerIfChanged(int centered) {
    if (centered < 0 || centered >= agendaList.length) return;
    final identity = _resolveFeedWarmIdentity(centered);
    if (_lastFeedWarmGroupIndex == identity.activeGroupIndex &&
        _lastFeedWarmBlockIndex == identity.activeBlockIndex) {
      return;
    }
    _lastFeedWarmGroupIndex = identity.activeGroupIndex;
    _lastFeedWarmBlockIndex = identity.activeBlockIndex;
    debugPrint(
      '[FeedWarmScheduler] block=${identity.activeBlockIndex} '
      'group=${identity.activeGroupInBlock + 1} '
      'hotGroupCount=$_feedHotPrefetchGroupCount',
    );
  }

  bool get _canRetainStartupPlaybackLock {
    if (_qaScrollStartedAt != null) {
      return false;
    }
    final lockedDocId = _startupLockedFeedDocId?.trim() ?? '';
    final lockedAt = _startupPlaybackLockedAt;
    if (lockedDocId.isEmpty || lockedAt == null) {
      return false;
    }
    var lockDuration = GetPlatform.isIOS
        ? _iosStartupPlaybackLockDuration
        : _startupPlaybackLockDuration;
    if (GetPlatform.isAndroid && agendaList.isNotEmpty) {
      final lockedIndex = agendaList.indexWhere(
        (post) => post.docID == lockedDocId,
      );
      if (lockedIndex >= 0 && lockedIndex < agendaList.length) {
        final lockedPlaybackKey = _feedPlaybackHandleKeyForDoc(lockedDocId);
        final lockedTargetActive = VideoStateManager.instance
            .isPlaybackTargetActive(lockedPlaybackKey);
        if (!lockedTargetActive) {
          lockDuration = _androidStartupPlaybackPendingLockDuration;
        }
      }
    }
    if (DateTime.now().difference(lockedAt) > lockDuration) {
      _startupLockedFeedDocId = null;
      _startupPlaybackLockedAt = null;
      return false;
    }
    return true;
  }

  void _lockStartupPlaybackTargetForIndex(int index) {
    if (_qaScrollStartedAt != null) {
      return;
    }
    if (index < 0 || index >= agendaList.length) return;
    _startupLockedFeedDocId = agendaList[index].docID;
    _startupPlaybackLockedAt = DateTime.now();
  }

  void _ensureFeedPlaybackForIndex(int index) {
    if (!canClaimPlaybackNow) return;
    if (index < 0 || index >= agendaList.length) return;
    final post = agendaList[index];
    if (!_canAutoplayVideoPost(post)) return;
    _boostFeedPlaybackHorizon(index);
    final playbackKey = _feedPlaybackHandleKeyForDoc(post.docID);
    final manager = VideoStateManager.instance;
    _reclaimFeedPlaybackFromExternalOwner(
      manager,
      source: 'ensure_feed_playback',
    );
    final now = DateTime.now();
    final pendingPlay = manager.hasPendingPlayFor(playbackKey);
    final canAttemptCurrentRecovery = !GetPlatform.isAndroid ||
        _lastPlaybackCommandDocId != playbackKey ||
        _lastPlaybackCommandAt == null ||
        now.difference(_lastPlaybackCommandAt!) > _androidCurrentRecoveryGrace;
    final needsCurrentRecovery = !pendingPlay &&
        canAttemptCurrentRecovery &&
        manager.currentPlayingDocID == playbackKey &&
        !manager.isPlaybackTargetActive(playbackKey);
    final shouldIssueImmediateCommand = needsCurrentRecovery ||
        (!pendingPlay &&
            manager.currentPlayingDocID != playbackKey &&
            (_lastPlaybackCommandDocId != playbackKey ||
                _lastPlaybackCommandAt == null ||
                now.difference(_lastPlaybackCommandAt!) >
                    const Duration(milliseconds: 120)));
    if (shouldIssueImmediateCommand) {
      final readyForImmediateHandoff =
          manager.canResumePlaybackFor(playbackKey);
      recordQALabPlaybackDispatch(
        surface: 'feed',
        stage: needsCurrentRecovery
            ? 'feed_reassert_only_this'
            : (readyForImmediateHandoff
                ? 'feed_play_only_this'
                : 'feed_defer_play_only_this'),
        metadata: <String, dynamic>{
          'docId': post.docID,
          'index': index,
          'currentPlayingDocID': manager.currentPlayingDocID ?? '',
          'readyForImmediateHandoff': readyForImmediateHandoff,
          'needsCurrentRecovery': needsCurrentRecovery,
          'pendingPlay': pendingPlay,
        },
      );
      final issuedAt = manager.activatePlaybackTargetIfReady(
        playbackKey,
        lastCommandDocId: _lastPlaybackCommandDocId,
        lastCommandAt: _lastPlaybackCommandAt,
      );
      if (issuedAt != null) {
        _lastPlaybackCommandDocId = playbackKey;
        _lastPlaybackCommandAt = issuedAt;
      }
    }
    if (needsCurrentRecovery) {
      _schedulePlaybackReassert(
        index: index,
        docId: post.docID,
        manager: manager,
      );
    }
  }

  void _bindCenteredIndexListener() {
    ever<int>(centeredIndex, (newIndex) {
      final videoManager = VideoStateManager.instance;
      final preserveExternalPlayback = _hasExternalPlaybackOwner(
        videoManager.currentPlayingDocID,
      );
      _notifyPlaybackRowUpdates(newIndex);

      if (playbackSuspended.value) {
        _cancelPendingPlaybackReassert();
        videoManager.pauseAllVideos(force: true);
        return;
      }

      if (!isPrimaryFeedRouteVisible) {
        _cancelPendingPlaybackReassert();
        if (!preserveExternalPlayback) {
          videoManager.pauseAllVideos(force: true);
        }
        return;
      }

      if (newIndex == -1) {
        _cancelPendingPlaybackReassert();
        if (preserveExternalPlayback && canClaimPlaybackNow) {
          _reclaimFeedPlaybackFromExternalOwner(
            videoManager,
            source: 'centered_index_empty',
          );
        } else if (_shouldPreserveFeedPlaybackAcrossCenteredGap(videoManager)) {
          _scheduleFeedPrefetch();
        } else if (!preserveExternalPlayback) {
          videoManager.pauseAllVideos();
        }
        return;
      }

      if (newIndex >= 0 && newIndex < agendaList.length) {
        final centeredPost = agendaList[newIndex];
        if (_canAutoplayVideoPost(centeredPost)) {
          _ensureFeedPlaybackForIndex(newIndex);
        } else {
          _cancelPendingPlaybackReassert();
          if (preserveExternalPlayback && canClaimPlaybackNow) {
            _reclaimFeedPlaybackFromExternalOwner(
              videoManager,
              source: 'centered_index_non_playable',
            );
          } else if (_shouldPreserveFeedPlaybackAcrossCenteredGap(
              videoManager)) {
            _scheduleFeedPrefetch();
          } else {
            videoManager.pauseAllVideos();
          }
        }
      }

      _recordFeedWarmSchedulerIfChanged(newIndex);
      _scheduleFeedPrefetch();
    });
  }

  void _scheduleFeedPrefetch({int attempt = 0}) {
    if (_renderWindowFrozenOnCellular) return;
    final readyForFeedPrefetch = !isLoading.value &&
        lastCenteredIndex != null &&
        renderFeedEntries.isNotEmpty &&
        centeredIndex.value >= 0;
    _feedPrefetchDebounce?.cancel();
    if (!readyForFeedPrefetch) {
      if (attempt >= 8) return;
      _feedPrefetchDebounce = Timer(const Duration(milliseconds: 320), () {
        _scheduleFeedPrefetch(attempt: attempt + 1);
      });
      return;
    }

    _prefetchCurrentPoster();
    _prefetchUpcomingImages();
    _prefetchThumbnailBatches();
    final centered = centeredIndex.value;
    if (centered >= 0 && centered < agendaList.length) {
      _boostFeedPlaybackHorizon(centered);
    }
    _feedPrefetchDebounce = Timer(const Duration(milliseconds: 240), () {
      _updateFeedPrefetchQueue();
    });
  }

  void _boostFeedPlaybackHorizon(int centered) {
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null || agendaList.isEmpty) return;
    final startupReadyThreshold = ReadBudgetRegistry.feedReadyForNavCount > 10
        ? ReadBudgetRegistry.feedReadyForNavCount
        : 10;
    final startupWindowStabilizing =
        prefetch.feedReadyCount < startupReadyThreshold;
    final prioritizedIndices = _resolvePrioritizedPlayableFeedIndices(
      centered: centered,
      lookAheadPlayableCount: _feedPlaybackBoostLookAhead,
      behindPlayableCount: 0,
    );
    if (prioritizedIndices.isEmpty) return;
    final targetOffsets = _resolveAheadPlayableOffsets(
      centered: centered,
      maxAheadPlayableCount: _feedPlaybackBoostLookAhead,
    );
    final secondSegmentOffsets = targetOffsets
        .where(
          (offset) => _feedSecondSegmentAheadPlayableOffsets.contains(offset),
        )
        .toSet();
    final maxBoosted = startupWindowStabilizing
        ? _feedPlaybackBoostLookAhead + 1
        : _feedBoostPlayableCount + 1;
    var boosted = 0;
    final boostLogs = <String>[];
    for (final index in prioritizedIndices) {
      final post = agendaList[index];
      if (!_canAutoplayVideoPost(post)) continue;
      final readySegments = _feedReadySegmentsForIndex(
        centered: centered,
        index: index,
        secondSegmentAheadOffsets: secondSegmentOffsets,
      );
      if (readySegments <= 0) {
        continue;
      }
      prefetch.boostDoc(
        post.docID,
        readySegments: readySegments,
      );
      final playableOffset = index == centered
          ? 0
          : _resolvePlayableOffsetFromCentered(
              centered: centered,
              targetIndex: index,
            );
      boostLogs.add(
        'idx=$index offset=$playableOffset doc=${post.docID} segments=$readySegments',
      );
      boosted++;
      if (boosted >= maxBoosted) {
        break;
      }
    }
    if (boostLogs.isNotEmpty) {
      debugPrint(
        '[FeedOnYukleme] phase=playback_horizon centered=$centered '
        'stabilizing=$startupWindowStabilizing entries=${boostLogs.join(' | ')}',
      );
    }
  }

  List<int> _resolvePrioritizedPlayableFeedIndices({
    required int centered,
    required int lookAheadPlayableCount,
    required int behindPlayableCount,
  }) {
    if (agendaList.isEmpty) {
      return const <int>[];
    }
    final safeCentered = centered.clamp(0, agendaList.length - 1);
    final indices = <int>[];

    void addIfPlayable(int index) {
      if (index < 0 || index >= agendaList.length) return;
      if (indices.contains(index)) return;
      if (!_canAutoplayVideoPost(agendaList[index])) return;
      indices.add(index);
    }

    addIfPlayable(safeCentered);

    var aheadFound = 0;
    for (int index = safeCentered + 1;
        index < agendaList.length && aheadFound < lookAheadPlayableCount;
        index++) {
      if (_canAutoplayVideoPost(agendaList[index])) {
        addIfPlayable(index);
        aheadFound++;
      }
    }

    var behindFound = 0;
    for (int index = safeCentered - 1;
        index >= 0 && behindFound < behindPlayableCount;
        index--) {
      if (_canAutoplayVideoPost(agendaList[index])) {
        addIfPlayable(index);
        behindFound++;
      }
    }

    return indices;
  }

  List<int> _resolveAheadPlayableOffsets({
    required int centered,
    required int maxAheadPlayableCount,
  }) {
    if (agendaList.isEmpty || maxAheadPlayableCount <= 0) {
      return const <int>[];
    }
    final safeCentered = centered.clamp(0, agendaList.length - 1);
    final offsets = <int>[];
    var playableOffset = 0;
    for (int index = safeCentered + 1;
        index < agendaList.length && playableOffset < maxAheadPlayableCount;
        index++) {
      if (!_canAutoplayVideoPost(agendaList[index])) continue;
      playableOffset++;
      offsets.add(playableOffset);
    }
    return offsets;
  }

  int _feedReadySegmentsForIndex({
    required int centered,
    required int index,
    required Set<int> secondSegmentAheadOffsets,
  }) {
    if (index < 0 || index >= agendaList.length) {
      return 0;
    }
    if (index == centered) {
      return StartupPreloadPolicy.activeReadySegments;
    }
    if (index < centered) {
      return 0;
    }
    var playableOffset = 0;
    for (int candidate = centered + 1;
        candidate <= index && candidate < agendaList.length;
        candidate++) {
      if (!_canAutoplayVideoPost(agendaList[candidate])) continue;
      playableOffset++;
      if (candidate != index) continue;
      return StartupPreloadPolicy.readySegmentsForAheadOffset(playableOffset);
    }
    return 0;
  }

  int _resolvePlayableOffsetFromCentered({
    required int centered,
    required int targetIndex,
  }) {
    if (targetIndex <= centered) {
      return targetIndex == centered ? 0 : -1;
    }
    var playableOffset = 0;
    for (int candidate = centered + 1;
        candidate <= targetIndex && candidate < agendaList.length;
        candidate++) {
      if (!_canAutoplayVideoPost(agendaList[candidate])) continue;
      playableOffset++;
      if (candidate == targetIndex) {
        return playableOffset;
      }
    }
    return -1;
  }

  int _feedStartupReadySegmentsForPlayableRank(int playableRank) {
    return StartupPreloadPolicy.startupReadySegmentsForRank(playableRank);
  }

  void _prefetchCurrentPoster() {
    if (agendaList.isEmpty) return;
    final current = centeredIndex.value.clamp(0, agendaList.length - 1);
    final post = agendaList[current];
    for (final posterUrl in post.preferredVideoPosterUrls) {
      TurqImageCacheManager.warmUrl(posterUrl).ignore();
    }
    if (post.img.isNotEmpty) {
      TurqImageCacheManager.warmUrl(post.img.first).ignore();
    }
  }

  void _updateFeedPrefetchQueue() {
    if (agendaList.isEmpty) return;

    _prefetchThumbnailBatches();
    _prefetchUpcomingImages();

    final centered = centeredIndex.value;
    final hotWindowPosts = _resolveFeedHotWindowPosts(
      centeredIndex: centered,
      hotGroupCount: _feedHotPrefetchGroupCount,
    );
    final videoPosts =
        hotWindowPosts.where((p) => _canAutoplayVideoPost(p)).toList();
    FeedSurfaceRegistry.recordVideoDocIds(
      videoPosts.map((post) => post.docID),
    );
    if (videoPosts.isEmpty) return;

    int safeCurrent = 0;
    if (centered >= 0 && centered < agendaList.length) {
      final centeredDocID = agendaList[centered].docID;
      final mapped = videoPosts.indexWhere((p) => p.docID == centeredDocID);
      if (mapped >= 0) {
        safeCurrent = mapped;
      } else {
        final safeCentered =
            centered >= 0 && centered < agendaList.length ? centered : 0;
        final hotWindowStart = _resolveFeedHotWindowStart(safeCentered);
        int beforeCount = 0;
        final relativeCentered = (safeCentered - hotWindowStart).clamp(
          0,
          hotWindowPosts.isEmpty ? 0 : hotWindowPosts.length - 1,
        );
        for (int i = 0; i < relativeCentered; i++) {
          if (_canAutoplayVideoPost(hotWindowPosts[i])) beforeCount++;
        }
        safeCurrent = beforeCount.clamp(0, videoPosts.length - 1);
      }
    }
    try {
      final scheduler = maybeFindPrefetchScheduler();
      scheduler?.updateFeedQueueForPosts(
        videoPosts,
        safeCurrent,
      );
    } catch (_) {}
  }

  int _resolveFeedWarmGroupIndex(int centered) {
    return _resolveFeedWarmIdentity(centered).activeGroupIndex;
  }

  int _resolveFeedWarmBlockIndex(int centered) {
    return _resolveFeedWarmIdentity(centered).activeBlockIndex;
  }

  int _resolveFeedWarmGroupInBlock(int centered) {
    return _resolveFeedWarmIdentity(centered).activeGroupInBlock;
  }

  int _resolveFeedHotWindowStart(int centered) {
    final hotGroup = _resolveFeedWarmGroupIndex(centered);
    return _resolveFeedWarmPostRange(
      startGroupIndex: hotGroup,
      hotGroupCount: _feedHotPrefetchGroupCount,
    ).start;
  }

  List<PostsModel> _resolveFeedHotWindowPosts({
    required int centeredIndex,
    required int hotGroupCount,
  }) {
    if (agendaList.isEmpty || hotGroupCount <= 0) {
      return const <PostsModel>[];
    }
    final hotGroup = _resolveFeedWarmGroupIndex(centeredIndex);
    final range = _resolveFeedWarmPostRange(
      startGroupIndex: hotGroup,
      hotGroupCount: hotGroupCount,
    );
    return agendaList
        .sublist(range.start, range.endExclusive)
        .toList(growable: false);
  }

  List<PostsModel> _resolveFeedStartupWarmPosts() {
    if (agendaList.isEmpty) return const <PostsModel>[];
    final range = _resolveFeedWarmPostRange(
      startGroupIndex: 0,
      hotGroupCount: _feedStartupWarmGroupCount,
    );
    return agendaList
        .sublist(range.start, range.endExclusive)
        .toList(growable: false);
  }

  void primeInitialCenteredPost() {
    final target = _agendaFeedApplicationService.resolveInitialCenteredIndex(
      agendaList: agendaList.toList(growable: false),
      pendingCenteredDocId: _pendingCenteredDocId,
      lastCenteredIndex: lastCenteredIndex,
      canAutoplayPost: _canAutoplayVideoPost,
    );
    if (target < 0 || target >= agendaList.length) return;
    final expectedDocId = _pendingCenteredDocId;
    centeredIndex.value = target;
    lastCenteredIndex = target;
    _lockStartupPlaybackTargetForIndex(target);
    _pendingCenteredDocId = null;
    final targetPost = agendaList[target];
    _invariantGuard.assertCenteredSelection(
      surface: 'feed',
      invariantKey: 'prime_initial_centered_post',
      centeredIndex: centeredIndex.value,
      docIds: agendaList.map((post) => post.docID).toList(growable: false),
      expectedDocId: expectedDocId,
      payload: <String, dynamic>{
        'target': target,
      },
    );
    if (!_canAutoplayVideoPost(targetPost)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed ||
          pauseAll.value ||
          !isPrimaryFeedRouteVisible ||
          centeredIndex.value != target ||
          target < 0 ||
          target >= agendaList.length ||
          agendaList[target].docID != targetPost.docID) {
        return;
      }
      void startPlaybackWork() {
        if (isClosed ||
            pauseAll.value ||
            !isPrimaryFeedRouteVisible ||
            centeredIndex.value != target ||
            target < 0 ||
            target >= agendaList.length ||
            agendaList[target].docID != targetPost.docID) {
          return;
        }
        if (canClaimPlaybackNow) {
          _ensureFeedPlaybackForIndex(target);
          if (!GetPlatform.isIOS) {
            _schedulePlaybackReassert(
              index: target,
              docId: targetPost.docID,
              manager: VideoStateManager.instance,
            );
          }
        }
        _scheduleStartupAutoplayKick(
          index: target,
          docId: targetPost.docID,
        );
      }

      final isAndroidStartupLead = GetPlatform.isAndroid &&
          target == 0 &&
          ((_lastPlaybackRowUpdateDocId?.trim().isEmpty ?? true)) &&
          ((VideoStateManager.instance.currentPlayingDocID?.trim().isEmpty ??
              true));
      if (_shouldDelayStartupPlaybackWork && !isAndroidStartupLead) {
        Future.delayed(_androidStartupPlaybackGrace, startPlaybackWork);
        return;
      }
      startPlaybackWork();
    });
  }

  bool get _shouldDelayStartupPlaybackWork {
    if (!GetPlatform.isAndroid) return false;
    if (agendaList.isEmpty) return false;
    if ((_lastPlaybackRowUpdateDocId?.trim().isNotEmpty ?? false)) {
      return false;
    }
    final currentOwner =
        VideoStateManager.instance.currentPlayingDocID?.trim() ?? '';
    if (currentOwner.startsWith('feed:')) return false;
    return true;
  }

  bool get _needsInitialFeedPlaybackPrime {
    if (agendaList.isEmpty) return false;
    final lastRowDocId = _lastPlaybackRowUpdateDocId?.trim() ?? '';
    if (lastRowDocId.isNotEmpty) return false;
    final currentOwner =
        VideoStateManager.instance.currentPlayingDocID?.trim() ?? '';
    if (currentOwner.startsWith('feed:')) return false;
    return true;
  }

  void resumeFeedPlayback() {
    if (!canClaimPlaybackNow) return;
    if (agendaList.isEmpty) return;

    pauseAll.value = false;
    final pendingCenteredDocId = _pendingCenteredDocId?.trim() ?? '';
    final expectedDocId =
        pendingCenteredDocId.isNotEmpty ? pendingCenteredDocId : null;
    int target = _agendaFeedApplicationService.resolveResumeIndex(
      agendaList: agendaList.toList(growable: false),
      pendingCenteredDocId: pendingCenteredDocId,
      lastCenteredIndex: lastCenteredIndex,
      centeredIndex: centeredIndex.value,
      visibleFractions: Map<int, double>.from(_visibleFractions),
      canAutoplayPost: _canAutoplayVideoPost,
    );

    if (target < 0 || target >= agendaList.length) return;
    lastCenteredIndex = target;
    final centeredChanged = centeredIndex.value != target;
    if (centeredChanged) {
      centeredIndex.value = target;
    }
    _lockStartupPlaybackTargetForIndex(target);
    _pendingCenteredDocId = null;
    _invariantGuard.assertCenteredSelection(
      surface: 'feed',
      invariantKey: 'resume_feed_playback',
      centeredIndex: centeredIndex.value,
      docIds: agendaList.map((post) => post.docID).toList(growable: false),
      expectedDocId: expectedDocId,
      payload: <String, dynamic>{
        'target': target,
      },
    );

    if (!centeredChanged) {
      _ensureFeedPlaybackForIndex(target);
    }
  }

  void _prefetchUpcomingImages() {
    if (agendaList.isEmpty) return;
    final current = centeredIndex.value.clamp(0, agendaList.length - 1);
    final start = max(0, current - 1);
    final end = (current + 4).clamp(0, agendaList.length);
    for (int i = start; i < end; i++) {
      final post = agendaList[i];
      if (post.img.isNotEmpty) {
        TurqImageCacheManager.warmUrl(post.img.first).ignore();
      }
      for (final posterUrl in post.preferredVideoPosterUrls) {
        TurqImageCacheManager.warmUrl(posterUrl).ignore();
      }
    }
  }

  void _prefetchThumbnailBatches() {
    if (agendaList.isEmpty) return;
    final current = centeredIndex.value.clamp(0, agendaList.length - 1);
    final start = max(
      0,
      current < _startupThumbnailPrefetchInitialCount
          ? 0
          : current - _startupThumbnailPrefetchRadius,
    );
    final end =
        min(agendaList.length, current + _startupThumbnailPrefetchRadius + 1);
    for (int i = start; i < end; i++) {
      final post = agendaList[i];
      if (!_prefetchedThumbnailDocIds.add(post.docID)) {
        continue;
      }
      if (post.img.isNotEmpty) {
        TurqImageCacheManager.warmUrl(post.img.first).ignore();
      }
      for (final previewUrl in post.preferredVideoPosterUrls) {
        TurqImageCacheManager.warmUrl(previewUrl).ignore();
      }
    }

    _prefetchedThumbnailPostCount = max(_prefetchedThumbnailPostCount, end);
    _warmReplayAdsForPreparedWindow(end - start);
  }

  void _warmReplayAdsForPreparedWindow(int preparedPostCount) {
    if (preparedPostCount <= 0) return;
    final prefetch = maybeFindPrefetchScheduler();
    final readyThreshold = ReadBudgetRegistry.feedReadyForNavCount;
    final startupWindowStabilizing =
        prefetch == null || prefetch.feedReadyCount < readyThreshold;
    if (startupWindowStabilizing) return;
    final targetAds = min(4, max(2, (preparedPostCount / 12).ceil()));
    unawaited(
      ensureAdmobBannerWarmupService().warmForSurfaceEntry(
        surfaceKey: 'feed:replay_overlay',
        targetCount: targetAds,
      ),
    );
  }

  void ensureFeedCacheWarm() {
    if (_renderWindowFrozenOnCellular) return;
    _scheduleFeedPrefetch();
  }

  void _schedulePlaybackReassert({
    required int index,
    required String docId,
    required VideoStateManager manager,
    int attempt = 0,
  }) {
    _playbackReassertTimer?.cancel();
    _playbackReassertTimer = Timer(
      _playbackReassertDelayForAttempt(attempt),
      () {
        if (!canClaimPlaybackNow) return;
        if (centeredIndex.value != index) return;
        if (index < 0 || index >= agendaList.length) return;
        if (agendaList[index].docID != docId) return;
        final playbackKey = _feedPlaybackHandleKeyForDoc(docId);
        if (manager.isPlaybackTargetActive(playbackKey)) return;
        final pendingPlay = manager.hasPendingPlayFor(playbackKey);
        if (pendingPlay) {
          if (attempt < 3) {
            _schedulePlaybackReassert(
              index: index,
              docId: docId,
              manager: manager,
              attempt: attempt + 1,
            );
          }
          return;
        }
        final issuedAt = manager.activatePlaybackTargetIfReady(
          playbackKey,
          lastCommandDocId: _lastPlaybackCommandDocId,
          lastCommandAt: _lastPlaybackCommandAt,
          minInterval: attempt == 0
              ? const Duration(milliseconds: 120)
              : const Duration(milliseconds: 80),
        );
        if (issuedAt != null) {
          _lastPlaybackCommandDocId = playbackKey;
          _lastPlaybackCommandAt = issuedAt;
          return;
        }
        final shouldRetry = attempt < 3 &&
            (manager.currentPlayingDocID == playbackKey ||
                !manager.canResumePlaybackFor(playbackKey) ||
                manager.hasPendingPlayFor(playbackKey));
        if (shouldRetry) {
          _schedulePlaybackReassert(
            index: index,
            docId: docId,
            manager: manager,
            attempt: attempt + 1,
          );
        }
      },
    );
  }

  void _scheduleStartupAutoplayKick({
    required int index,
    required String docId,
  }) {
    if (!GetPlatform.isAndroid) return;
    final playbackKey = _feedPlaybackHandleKeyForDoc(docId);
    final isStartupLeadKick = index == 0 &&
        (_lastPlaybackRowUpdateDocId?.trim().isEmpty ?? true) &&
        (VideoStateManager.instance.currentPlayingDocID?.trim().isEmpty ??
            true);
    final delays = isStartupLeadKick
        ? const <Duration>[
            Duration(milliseconds: 180),
            Duration(milliseconds: 520),
            Duration(milliseconds: 1100),
            Duration(milliseconds: 2200),
          ]
        : const <Duration>[
            Duration(milliseconds: 900),
            Duration(milliseconds: 2200),
            Duration(milliseconds: 3800),
          ];
    for (final delay in delays) {
      Future.delayed(delay, () {
        if (isClosed ||
            pauseAll.value ||
            !canClaimPlaybackNow ||
            !isPrimaryFeedRouteVisible ||
            centeredIndex.value != index ||
            index < 0 ||
            index >= agendaList.length ||
            agendaList[index].docID != docId) {
          return;
        }
        final manager = VideoStateManager.instance;
        if (manager.isPlaybackTargetActive(playbackKey)) {
          return;
        }
        final resumed = manager.resumeCurrentPlaybackIfReady(playbackKey);
        if (!resumed) {
          _ensureFeedPlaybackForIndex(index);
        }
      });
    }
  }

  void _cancelPendingPlaybackReassert() {
    _playbackReassertTimer?.cancel();
    _playbackReassertTimer = null;
  }

  String feedPlaybackRowUpdateId(String docId) => 'feed-playback-row-$docId';

  void _notifyPlaybackRowUpdates(int newIndex) {
    final ids = <String>{};
    final previousDocId = _lastPlaybackRowUpdateDocId?.trim() ?? '';
    if (previousDocId.isNotEmpty) {
      ids.add(feedPlaybackRowUpdateId(previousDocId));
    }
    String? nextDocId;
    if (newIndex >= 0) {
      nextDocId = agendaList[newIndex].docID;
      ids.add(feedPlaybackRowUpdateId(nextDocId));
    }
    _lastPlaybackRowUpdateDocId = nextDocId;
    if (ids.isNotEmpty) {
      update(ids.toList(growable: false));
    }
  }

  bool _isPlaybackTargetCurrent(int index) {
    if (index < 0 || index >= agendaList.length) return false;
    return VideoStateManager.instance.isPlaybackTargetActive(
      _feedPlaybackHandleKeyForDoc(agendaList[index].docID),
    );
  }

  GlobalKey getAgendaKeyForDoc(String docID) {
    return _agendaKeys.putIfAbsent(
      docID,
      () => GlobalObjectKey("agenda_$docID"),
    );
  }

  void _onScroll() {
    final currentOffset = scrollController.offset;
    final now = DateTime.now();
    final scrollDelta = (currentOffset - lastOffset).abs();
    final startupLockActive = _canRetainStartupPlaybackLock;
    // Ignore small cold-start layout/inset jitters on iOS while the initial
    // autoplay target is locked. A real user scroll quickly exceeds this.
    final startupUnlockThreshold = startupLockActive ? 2.0 : 1.0;
    final hasMeaningfulScrollMovement =
        currentOffset.abs() > startupUnlockThreshold ||
            scrollDelta > startupUnlockThreshold;
    if (_qaScrollStartedAt == null) {
      if (!hasMeaningfulScrollMovement) {
        lastOffset = currentOffset;
        return;
      }
      _startupLockedFeedDocId = null;
      _startupPlaybackLockedAt = null;
      _qaScrollStartedAt = now;
      _qaScrollStartOffset = currentOffset;
      _qaActiveScrollToken =
          'feed-${now.microsecondsSinceEpoch}-${_qaScrollSequence++}';
      recordQALabScrollEvent(
        surface: 'feed',
        phase: 'start',
        metadata: <String, dynamic>{
          'scrollToken': _qaActiveScrollToken,
          'offset': currentOffset,
          'count': agendaList.length,
          'centeredIndex': centeredIndex.value,
          'centeredDocId': centeredIndex.value >= 0 &&
                  centeredIndex.value < agendaList.length
              ? agendaList[centeredIndex.value].docID
              : '',
        },
      );
    }
    bool shouldShowNavBar;

    if (currentOffset <= 0) {
      shouldShowNavBar = true;
    } else {
      if (currentOffset > lastOffset) {
        shouldShowNavBar = false;
      } else if (currentOffset < lastOffset) {
        shouldShowNavBar = true;
      } else {
        shouldShowNavBar = navBarController.showBar.value;
      }
    }
    if (navBarController.showBar.value != shouldShowNavBar) {
      navBarController.showBar.value = shouldShowNavBar;
    }
    lastOffset = currentOffset;

    final centered = centeredIndex.value;
    final viewedCount =
        centered >= 0 && centered < agendaList.length ? centered + 1 : 0;
    final normalTriggerReached = viewedCount >= _nextPageFetchTriggerCount;
    if (agendaList.isNotEmpty &&
        scrollController.position.hasContentDimensions &&
        hasMore.value &&
        !isLoading.value &&
        normalTriggerReached) {
      final triggerCount = _nextPageFetchTriggerCount;
      final activeBlock = _resolveFeedWarmBlockIndex(centered);
      final activeGroupInBlock = _resolveFeedWarmGroupInBlock(centered);
      debugPrint(
        '[FeedFetchTrigger] viewedCount=$viewedCount currentCount=${agendaList.length} '
        'pageLimit=${ReadBudgetRegistry.feedPageFetchLimit} '
        'triggerCount=$triggerCount block=$activeBlock group=$activeGroupInBlock '
        'resolvedViewedCount=$viewedCount',
      );
      _advanceFeedPageFetchTrigger(viewedCount);
      recordQALabScrollEvent(
        surface: 'feed',
        phase: 'near_end',
        metadata: <String, dynamic>{
          'scrollToken': _qaActiveScrollToken,
          'offset': currentOffset,
          'maxScrollExtent': scrollController.position.maxScrollExtent,
          'count': agendaList.length,
          'viewedCount': viewedCount,
          'nextTriggerCount': _nextPageFetchTriggerCount,
          'activeBlock': activeBlock,
          'activeGroupInBlock': activeGroupInBlock,
        },
      );
      fetchAgendaBigData(
        pageLimit: ReadBudgetRegistry.feedPageFetchLimit,
        trigger: 'scroll_near_end',
      );
    }
    _maybeScheduleConnectedFeedReservoirForViewedCount(viewedCount);

    final shouldShowFab = currentOffset <= 1000;
    if (showFAB.value != shouldShowFab) {
      showFAB.value = shouldShowFab;
    }

    _scrollIdleDebounce?.cancel();
    _scrollIdleDebounce = Timer(
      const Duration(milliseconds: 220),
      () {
        final settledAt = DateTime.now();
        final settledOffset = scrollController.hasClients
            ? scrollController.offset
            : currentOffset;
        final scrollDistance = settledOffset - _qaScrollStartOffset;
        final centered = centeredIndex.value;
        final centeredDocId = centered >= 0 && centered < agendaList.length
            ? agendaList[centered].docID
            : '';
        recordQALabScrollEvent(
          surface: 'feed',
          phase: 'settled',
          metadata: <String, dynamic>{
            'scrollToken': _qaActiveScrollToken,
            'offset': settledOffset,
            'distance': scrollDistance,
            'durationMs': settledAt
                .difference(_qaScrollStartedAt ?? settledAt)
                .inMilliseconds,
            'centeredIndex': centered,
            'docId': centeredDocId,
            'count': agendaList.length,
          },
        );
        _qaLatestScrollToken = _qaActiveScrollToken;
        _qaScrollStartedAt = null;
        _qaScrollStartOffset = 0.0;
        _qaActiveScrollToken = '';
        if (centered < 0 || centered >= agendaList.length) {
          resumeFeedPlayback();
        }
      },
    );
  }

  void disposeAgendaContentController(String docID) {
    if (AgendaContentController.maybeFind(tag: docID) != null) {
      Get.delete<AgendaContentController>(tag: docID, force: true);
      print("Disposed AgendaContentController");
    }
  }

  void markHighlighted(List<String> docIDs, {Duration? keepFor}) {
    highlightDocIDs.addAll(docIDs);
    final d = keepFor ?? const Duration(seconds: 2);
    Future.delayed(d, () {
      highlightDocIDs.removeAll(docIDs);
    });
  }
}
