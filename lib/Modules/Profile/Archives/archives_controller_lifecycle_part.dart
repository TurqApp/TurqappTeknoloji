part of 'archives_controller.dart';

extension _ArchiveControllerLifecyclePart on ArchiveController {
  void handleOnInit() {
    scrollController.addListener(_onScroll);
    _bindAuth();
  }

  void handleOnClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _visibilityDebounce?.cancel();
    _scrollSettleDebounce?.cancel();
    _visibleFractions.clear();
    _visibleUpdatedAt.clear();
    _authSub?.cancel();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final currentOffset = position.pixels;
    final signedScrollDelta = currentOffset - _lastObservedOffset;
    final scrollDelta = signedScrollDelta.abs();
    if (scrollDelta > 1.0) {
      if (_scrollStartedAt == null) {
        _scrollStartedAt = DateTime.now();
        _scrollStartOffset = currentOffset;
        _scrollDirection = 0;
      }
      _scrollDirection =
          FeedPlaybackSelectionPolicy.resolveStableScrollDirection(
        currentDirection: _scrollDirection,
        scrollStartOffset: _scrollStartOffset,
        currentOffset: currentOffset,
        signedScrollDelta: signedScrollDelta,
      );
      _scrollSettleDebounce?.cancel();
      _scrollSettleDebounce = Timer(
        FeedPlaybackSelectionPolicy.scrollSettleReassertDuration,
        () {
          _scrollStartedAt = null;
          _scrollStartOffset = 0.0;
          _scrollDirection = 0;
        },
      );
    }
    _lastObservedOffset = currentOffset;
    if (position.pixels >= position.maxScrollExtent - 300) {
      fetchData();
    }
    if (list.isEmpty) return;
    if (position.pixels <= 0) {
      centeredIndex.value = 0;
      currentVisibleIndex.value = 0;
      lastCenteredIndex = 0;
      capturePendingCenteredEntry(preferredIndex: 0);
      return;
    }
    if (_visibleFractions.isNotEmpty) return;
    final estimatedItemExtent = (position.viewportDimension * 0.74).clamp(
      320.0,
      680.0,
    );
    final nextIndex = (((position.pixels + position.viewportDimension * 0.25) /
                estimatedItemExtent)
            .floor())
        .clamp(0, list.length - 1);
    if (centeredIndex.value != nextIndex) {
      if (lastCenteredIndex != null && lastCenteredIndex != nextIndex) {
        final prevModel = list[lastCenteredIndex!];
        disposeAgendaContentController(prevModel.docID);
      }
      centeredIndex.value = nextIndex;
      currentVisibleIndex.value = nextIndex;
      lastCenteredIndex = nextIndex;
      capturePendingCenteredEntry(preferredIndex: nextIndex);
    }
  }

  void _bindAuth() {
    _authSub = CurrentUserService.instance.authStateChanges().listen((user) {
      final nextUserId = user?.uid;
      if (_currentUserId != nextUserId) {
        _currentUserId = nextUserId;
        list.clear();
      }
      if (nextUserId == null) {
        isLoading.value = false;
        return;
      }
      if (IntegrationTestMode.skipBackgroundStartupWork) {
        isLoading.value = false;
        return;
      }
      unawaited(_ArchiveControllerDataPart(this)._bootstrapArchive(nextUserId));
    });
  }
}
