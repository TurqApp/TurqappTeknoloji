part of 'agenda_controller.dart';

extension AgendaControllerRenderPart on AgendaController {
  void _scheduleStartupPromoReveal({int attempt = 0}) {
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
      final readyThreshold = ReadBudgetRegistry.feedReadyForNavCount;
      final waitingForStartupPromoWindow = prefetch == null ||
          prefetch.feedWindowCount < readyThreshold ||
          prefetch.feedReadyCount < readyThreshold;
      if (attempt < 8 && waitingForStartupPromoWindow) {
        _scheduleStartupPromoReveal(attempt: attempt + 1);
        return;
      }
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

  void _performRebuildRenderFeedEntries() {
    if (filteredFeedEntries.isEmpty) {
      if (isLoading.value && renderFeedEntries.isNotEmpty) {
        return;
      }
      _startupPromoRevealTimer?.cancel();
      _startupPromoRevealTimer = null;
      _startupPromoRevealQueued = false;
      renderFeedEntries.clear();
      return;
    }
    final shouldDeferStartupPromos =
        _startupPresentationApplied && renderFeedEntries.isEmpty;
    final renderEntries = _feedRenderCoordinator.buildRenderEntries(
      filteredEntries: filteredFeedEntries.toList(growable: false),
      includePromos: !shouldDeferStartupPromos,
    );
    final patch = _feedRenderCoordinator.buildPatch(
      previous: renderFeedEntries.toList(growable: false),
      next: renderEntries,
      reason: 'render_feed_rebuild',
    );
    _feedRenderCoordinator.applyPatch(renderFeedEntries, patch);
    if (shouldDeferStartupPromos) {
      _scheduleStartupPromoReveal();
    }
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
