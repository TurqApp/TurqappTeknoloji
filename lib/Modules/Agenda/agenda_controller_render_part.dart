part of 'agenda_controller.dart';

extension AgendaControllerRenderPart on AgendaController {
  static const Duration _growthRenderReleaseDelay =
      Duration(milliseconds: 34);

  void _activateStartupRenderStages({String reason = 'unknown'}) {
    debugPrint(
      '[FeedStartupStage] status=activate reason=$reason '
      'visibleEntries=${FeedRenderBlockPlan.renderSlotsPerBlock}',
    );
  }

  void _applyStartupRenderStagesNow() {
    if (agendaList.isEmpty) {
      _startupRenderBootstrapHold = false;
      return;
    }
    _rebuildMergedFeedEntries();
    _rebuildFilteredFeedEntries();
    debugPrint(
      '[FeedStartupStage] status=sync_rebuild visibleEntries=${FeedRenderBlockPlan.renderSlotsPerBlock} '
      'agendaCount=${agendaList.length}',
    );
    _rebuildRenderFeedEntries(ignoreStartupBootstrapHold: true);
    _startupRenderBootstrapHold = false;
  }

  void _resetStartupRenderStages() {
    _startupRenderBootstrapHold = false;
  }

  void _scheduleGrowthRenderRelease({
    required String reason,
    required int itemCount,
  }) {
    _growthRenderReleaseTimer?.cancel();
    _growthRenderAppendHold = true;
    final token = _growthRenderAppendEpoch + 1;
    _growthRenderAppendEpoch = token;
    debugPrint(
      '[FeedGrowthRender] status=hold reason=$reason itemCount=$itemCount '
      'delayMs=${_growthRenderReleaseDelay.inMilliseconds}',
    );
    _growthRenderReleaseTimer = Timer(_growthRenderReleaseDelay, () {
      if (isClosed || _growthRenderAppendEpoch != token) return;
      _growthRenderReleaseTimer = null;
      _growthRenderAppendHold = false;
      debugPrint(
        '[FeedGrowthRender] status=release reason=$reason itemCount=$itemCount',
      );
      _rebuildRenderFeedEntries(ignoreGrowthAppendHold: true);
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
    bool ignoreGrowthAppendHold = false,
  }) {
    if (_startupRenderBootstrapHold && !ignoreStartupBootstrapHold) {
      return;
    }
    if (_growthRenderAppendHold && !ignoreGrowthAppendHold) {
      return;
    }
    if (filteredFeedEntries.isEmpty) {
      if (isLoading.value && renderFeedEntries.isNotEmpty) {
        return;
      }
      _resetStartupRenderStages();
      _growthRenderAppendHold = false;
      renderFeedEntries.clear();
      return;
    }
    final renderEntries = _feedRenderCoordinator.buildRenderEntries(
      filteredEntries: filteredFeedEntries.toList(growable: false),
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
