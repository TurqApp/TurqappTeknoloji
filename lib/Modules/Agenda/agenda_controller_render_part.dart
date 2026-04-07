part of 'agenda_controller.dart';

extension AgendaControllerRenderPart on AgendaController {
  static const List<int> _startupRenderStageEntryCounts = <int>[
    5,
    10,
    20,
    30,
    40,
  ];

  Duration _startupRenderStageDelay(int currentCount) {
    if (!GetPlatform.isAndroid) {
      return currentCount <= _startupRenderStageEntryCounts.first
          ? const Duration(milliseconds: 90)
          : const Duration(milliseconds: 140);
    }
    return currentCount <= _startupRenderStageEntryCounts.first
        ? const Duration(milliseconds: 180)
        : const Duration(milliseconds: 220);
  }

  void _activateStartupRenderStages({String reason = 'unknown'}) {
    _startupRenderStageTimer?.cancel();
    _startupRenderStageTimer = null;
    _startupRenderStagingActive = true;
    _startupRenderVisiblePostCount = _startupRenderStageEntryCounts.first;
    debugPrint(
      '[FeedStartupStage] status=activate reason=$reason '
      'visibleEntries=$_startupRenderVisiblePostCount',
    );
    _scheduleStartupRenderStageAdvance();
  }

  void _applyStartupRenderStagesNow() {
    if (agendaList.isEmpty) {
      _startupRenderBootstrapHold = false;
      return;
    }
    _rebuildMergedFeedEntries();
    _rebuildFilteredFeedEntries();
    debugPrint(
      '[FeedStartupStage] status=sync_rebuild visibleEntries=$_startupRenderVisiblePostCount '
      'agendaCount=${agendaList.length}',
    );
    _rebuildRenderFeedEntries(ignoreStartupBootstrapHold: true);
    _startupRenderBootstrapHold = false;
  }

  void _resetStartupRenderStages() {
    _startupRenderStageTimer?.cancel();
    _startupRenderStageTimer = null;
    _startupRenderStagingActive = false;
    _startupRenderVisiblePostCount = 0;
    _startupRenderBootstrapHold = false;
  }

  int? _nextStartupRenderStageEntryCount(int currentCount) {
    for (final target in _startupRenderStageEntryCounts) {
      if (target > currentCount) return target;
    }
    return null;
  }

  void _scheduleStartupRenderStageAdvance() {
    if (!_startupRenderStagingActive) return;
    final currentCount = _startupRenderVisiblePostCount;
    if (currentCount >= _startupRenderStageEntryCounts.last) {
      _resetStartupRenderStages();
      return;
    }
    final nextStageCount = _nextStartupRenderStageEntryCount(currentCount);
    if (nextStageCount == null) {
      _resetStartupRenderStages();
      return;
    }
    _startupRenderStageTimer?.cancel();
    _startupRenderStageTimer = Timer(
      _startupRenderStageDelay(currentCount),
      () {
        _startupRenderStageTimer = null;
        if (isClosed || !_startupRenderStagingActive) return;
        _startupRenderVisiblePostCount = nextStageCount;
        debugPrint(
          '[FeedStartupStage] status=advance visibleEntries=$nextStageCount',
        );
        _rebuildRenderFeedEntries();
        if (nextStageCount >= _startupRenderStageEntryCounts.last) {
          _resetStartupRenderStages();
          _rebuildRenderFeedEntries();
          return;
        }
        _scheduleStartupRenderStageAdvance();
      },
    );
  }

  void _scheduleStartupPromoReveal({int attempt = 0}) {
    if (!_startupPromoRevealUnlockedByScroll) {
      return;
    }
    if (_startupPromoRevealQueued ||
        _startupPromoRevealTimer?.isActive == true) {
      return;
    }
    _startupPromoRevealQueued = true;
    final delay = attempt == 0
        ? const Duration(milliseconds: 450)
        : const Duration(milliseconds: 700);
    _startupPromoRevealTimer = Timer(delay, () {
      _startupPromoRevealTimer = null;
      _startupPromoRevealQueued = false;
      if (isClosed ||
          filteredFeedEntries.isEmpty ||
          renderFeedEntries.isEmpty) {
        return;
      }
      final prefetch = maybeFindPrefetchScheduler();
      final navReadyThreshold = ReadBudgetRegistry.feedReadyForNavCount;
      final readyThreshold = navReadyThreshold < 10 ? 10 : navReadyThreshold;
      final waitingForStartupPromoWindow = prefetch == null ||
          prefetch.feedWindowCount < readyThreshold ||
          prefetch.feedReadyCount < readyThreshold;
      if (attempt < 24 && waitingForStartupPromoWindow) {
        if (attempt == 0 || attempt % 8 == 0) {
          recordQALabFeedFetchEvent(
            stage: 'startup_promo_reveal_wait',
            trigger: 'startup_promo_ready_window',
            metadata: <String, dynamic>{
              'attempt': attempt,
              'unlockedByScroll': _startupPromoRevealUnlockedByScroll,
              'feedReadyCount': prefetch?.feedReadyCount ?? -1,
              'feedWindowCount': prefetch?.feedWindowCount ?? -1,
              'readyThreshold': readyThreshold,
              'renderCount': renderFeedEntries.length,
              'filteredCount': filteredFeedEntries.length,
            },
          );
        }
        _scheduleStartupPromoReveal(attempt: attempt + 1);
        return;
      }
      recordQALabFeedFetchEvent(
        stage: 'startup_promo_reveal_apply',
        trigger: 'startup_promo_ready_window',
        metadata: <String, dynamic>{
          'attempt': attempt,
          'unlockedByScroll': _startupPromoRevealUnlockedByScroll,
          'feedReadyCount': prefetch?.feedReadyCount ?? -1,
          'feedWindowCount': prefetch?.feedWindowCount ?? -1,
          'readyThreshold': readyThreshold,
          'renderCount': renderFeedEntries.length,
          'filteredCount': filteredFeedEntries.length,
        },
      );
      _startupPromoRevealApplied = true;
      _rebuildRenderFeedEntries();
    });
  }

  void _performBindMergedFeedEntries() {
    _mergedFeedWorker?.dispose();
    _mergedFeedWorker = everAll(
      [agendaList, feedReshareEntries],
      (_) => _rebuildMergedFeedEntries(),
    );
    _rebuildMergedFeedEntries();
  }

  void _performBindFilteredFeedEntries() {
    _filteredFeedWorker?.dispose();
    _filteredFeedWorker = everAll(
      [
        mergedFeedEntries,
        feedViewMode,
        followingIDs,
        CurrentUserService.instance.currentUserRx,
        isLoading,
      ],
      (_) => _rebuildFilteredFeedEntries(),
    );
    _rebuildFilteredFeedEntries();
  }

  void _performBindRenderFeedEntries() {
    _renderFeedWorker?.dispose();
    _renderFeedWorker = ever<List<Map<String, dynamic>>>(
      filteredFeedEntries,
      (_) => _rebuildRenderFeedEntries(),
    );
    _rebuildRenderFeedEntries();
  }

  void _performRebuildMergedFeedEntries() {
    if (agendaList.isEmpty && feedReshareEntries.isEmpty) {
      if (isLoading.value && mergedFeedEntries.isNotEmpty) {
        return;
      }
      mergedFeedEntries.clear();
      return;
    }
    final merged = _feedRenderCoordinator.buildMergedEntries(
      agendaList: agendaList.toList(growable: false),
      feedReshareEntries: feedReshareEntries.toList(growable: false),
      myReshares: Map<String, int>.from(myReshares),
      currentUserId: CurrentUserService.instance.effectiveUserId,
    );
    final patch = _feedRenderCoordinator.buildPatch(
      previous: mergedFeedEntries.toList(growable: false),
      next: merged,
      reason: 'merged_feed_rebuild',
    );
    _feedRenderCoordinator.applyPatch(mergedFeedEntries, patch);
  }

  void _performRebuildFilteredFeedEntries() {
    if (mergedFeedEntries.isEmpty) {
      if (isLoading.value && filteredFeedEntries.isNotEmpty) {
        return;
      }
      _cancelQueuedFeedModeFallback();
      filteredFeedEntries.clear();
      return;
    }
    var filtered = _feedRenderCoordinator.filterEntries(
      mergedEntries: mergedFeedEntries.toList(growable: false),
      isFollowingMode: isFollowingMode,
      isCityMode: isCityMode,
      followingIds: followingIDs.toSet(),
      currentUserId: CurrentUserService.instance.effectiveUserId,
      city: currentUserLocationCity,
    );
    final shouldFallbackToForYou =
        filtered.isEmpty && !isLoading.value && (isFollowingMode || isCityMode);
    if (shouldFallbackToForYou) {
      filtered = mergedFeedEntries.toList(growable: false);
      _queueFeedModeFallbackToForYou();
    } else {
      _cancelQueuedFeedModeFallback();
    }
    final patch = _feedRenderCoordinator.buildPatch(
      previous: filteredFeedEntries.toList(growable: false),
      next: filtered,
      reason: 'filtered_feed_rebuild',
    );
    _feedRenderCoordinator.applyPatch(filteredFeedEntries, patch);
  }

  void _performRebuildRenderFeedEntries({
    bool ignoreStartupBootstrapHold = false,
  }) {
    if (_startupRenderBootstrapHold && !ignoreStartupBootstrapHold) {
      return;
    }
    if (filteredFeedEntries.isEmpty) {
      if (_startupRenderStagingActive && agendaList.isNotEmpty) {
        return;
      }
      if (isLoading.value && renderFeedEntries.isNotEmpty) {
        return;
      }
      _resetStartupRenderStages();
      _startupPromoRevealTimer?.cancel();
      _startupPromoRevealTimer = null;
      _startupPromoRevealQueued = false;
      _startupPromoRevealApplied = false;
      renderFeedEntries.clear();
      return;
    }
    final renderEntries = _feedRenderCoordinator.buildRenderEntries(
      filteredEntries: filteredFeedEntries.toList(growable: false),
      maxRenderEntries:
          _startupRenderStagingActive ? _startupRenderVisiblePostCount : null,
    );
    final patch = _feedRenderCoordinator.buildPatch(
      previous: renderFeedEntries.toList(growable: false),
      next: renderEntries,
      reason: 'render_feed_rebuild',
    );
    _feedRenderCoordinator.applyPatch(renderFeedEntries, patch);
  }

  void _queueFeedModeFallbackToForYou() {
    if (_feedModeFallbackQueued || feedViewMode.value == FeedViewMode.forYou) {
      return;
    }
    _feedModeFallbackQueued = true;
    final token = ++_feedModeFallbackEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed || _feedModeFallbackEpoch != token) return;
      _feedModeFallbackQueued = false;
      if (feedViewMode.value == FeedViewMode.forYou) return;
      if (isLoading.value || mergedFeedEntries.isEmpty) return;
      final fallbackStillNeeded = _feedRenderCoordinator
          .filterEntries(
            mergedEntries: mergedFeedEntries.toList(growable: false),
            isFollowingMode: isFollowingMode,
            isCityMode: isCityMode,
            followingIds: followingIDs.toSet(),
            currentUserId: CurrentUserService.instance.effectiveUserId,
            city: currentUserLocationCity,
          )
          .isEmpty;
      if (!fallbackStillNeeded) return;
      setFeedViewMode(FeedViewMode.forYou);
    });
  }

  void _cancelQueuedFeedModeFallback() {
    _feedModeFallbackEpoch++;
    _feedModeFallbackQueued = false;
  }
}
