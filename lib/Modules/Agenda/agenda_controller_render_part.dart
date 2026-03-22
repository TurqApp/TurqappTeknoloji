part of 'agenda_controller.dart';

extension AgendaControllerRenderPart on AgendaController {
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
      mergedFeedEntries.clear();
      return;
    }
    final merged = _feedRenderCoordinator.buildMergedEntries(
      agendaList: agendaList.toList(growable: false),
      feedReshareEntries: feedReshareEntries.toList(growable: false),
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
      filteredFeedEntries.clear();
      return;
    }
    final filtered = _feedRenderCoordinator.filterEntries(
      mergedEntries: mergedFeedEntries.toList(growable: false),
      isFollowingMode: isFollowingMode,
      isCityMode: isCityMode,
      followingIds: followingIDs.toSet(),
      city: currentUserLocationCity,
    );
    final patch = _feedRenderCoordinator.buildPatch(
      previous: filteredFeedEntries.toList(growable: false),
      next: filtered,
      reason: 'filtered_feed_rebuild',
    );
    _feedRenderCoordinator.applyPatch(filteredFeedEntries, patch);
  }

  void _performRebuildRenderFeedEntries() {
    if (filteredFeedEntries.isEmpty) {
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
}
