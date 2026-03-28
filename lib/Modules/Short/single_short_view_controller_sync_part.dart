part of 'single_short_view.dart';

extension SingleShortViewControllerSyncPart on _SingleShortViewState {
  void _handleShortsChange(List<PostsModel> list) {
    final previous = List<PostsModel>.from(_renderedShorts);
    if (previous.isEmpty) {
      _configureInitialForList(list);
      return;
    }

    final update = _shortRenderCoordinator.buildUpdate(
      previous: previous,
      next: list,
      currentIndex: currentPage,
    );
    if (update.patch.isEmpty) {
      _renderedShorts = List<PostsModel>.from(list);
      return;
    }

    final oldControllers = Map<int, HLSVideoAdapter>.from(_videoControllers);
    final oldExternallyOwned = Set<int>.from(_externallyOwned);
    final oldCompletionTriggered = Map<int, bool>.from(_completionTriggered);
    _videoControllers.clear();
    _externallyOwned.clear();
    _completionTriggered.clear();

    if (list.isEmpty) {
      for (final entry in oldControllers.entries) {
        final controller = entry.value;
        _detachCompletionListener(entry.key, controller);
        if (widget.injectedController != null &&
            identical(controller, widget.injectedController)) {
          continue;
        }
        unawaited(_videoPool.release(controller, keepWarm: true));
      }
      _renderedShorts = const <PostsModel>[];
      currentPage = 0;
      _refreshView();
      return;
    }

    final retained = <int>{};
    for (final entry in oldControllers.entries) {
      final oldIndex = entry.key;
      final controller = entry.value;
      if (oldIndex < 0 || oldIndex >= previous.length) {
        if (!(widget.injectedController != null &&
            identical(controller, widget.injectedController))) {
          unawaited(_videoPool.release(controller, keepWarm: true));
        }
        continue;
      }

      final docId = previous[oldIndex].docID;
      final newIndex = list.indexWhere((item) => item.docID == docId);
      _detachCompletionListener(oldIndex, controller);

      if (newIndex == -1) {
        if (!(widget.injectedController != null &&
            identical(controller, widget.injectedController))) {
          unawaited(_videoPool.release(controller, keepWarm: true));
        }
        continue;
      }

      retained.add(newIndex);
      _videoControllers[newIndex] = controller;
      if (oldExternallyOwned.contains(oldIndex)) {
        _externallyOwned.add(newIndex);
      }
      final wasCompleted = oldCompletionTriggered[oldIndex];
      if (wasCompleted != null) {
        _completionTriggered[newIndex] = wasCompleted;
      }
      _addVideoCompletionListener(controller, newIndex);
    }

    currentPage = update.remappedIndex.clamp(0, list.length - 1);
    _renderedShorts = List<PostsModel>.from(list);

    if (list.isNotEmpty && currentPage >= 0 && currentPage < list.length) {
      try {
        _playbackRuntimeService.enterExclusiveMode(list[currentPage].docID);
      } catch (_) {}
    }

    if (!retained.contains(currentPage)) {
      _ensureController(currentPage);
    }
    _preloadRange(currentPage);
    _disposeOutsideRange(currentPage);
    _primePlaybackForIndex(currentPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !pageController.hasClients) return;
      try {
        pageController.jumpToPage(currentPage);
      } catch (_) {}
    });

    _refreshView();
  }
}
