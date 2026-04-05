part of 'profile_controller.dart';

extension ProfileControllerLifecyclePart on ProfileController {
  void _performResetSurfaceForTabTransition() {
    postSelection.value = 0;
    centeredIndex.value = mergedPosts.isEmpty ? -1 : 0;
    currentVisibleIndex.value = mergedPosts.isEmpty ? -1 : 0;
    lastCenteredIndex = mergedPosts.isEmpty ? null : 0;
    _pendingCenteredIdentity = null;
    _visibleFractions.clear();
    pausetheall.value = false;
    showPfImage.value = false;
    showScrollToTop.value = false;

    void resetController(ScrollController controller) {
      if (!controller.hasClients) return;
      try {
        controller.jumpTo(0);
      } catch (_) {}
    }

    for (final controller in _scrollControllers.values) {
      resetController(controller);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in _scrollControllers.values) {
        resetController(controller);
      }
    });
  }

  Future<void> _performRefreshAll({bool forceSync = false}) async {
    try {
      await _performBootstrapHeaderFromTypesense();
      await getCounters();

      await Future.wait([
        _loadInitialPrimaryBuckets(forceSync: forceSync),
        getReshares(),
      ]);
    } catch (e) {
      print('refreshAll error: $e');
    }
  }

  String? _performResolvedActiveUid() {
    final active = _activeUid?.trim();
    if (active != null && active.isNotEmpty) return active;
    final effectiveUid = userService.effectiveUserId.trim();
    if (effectiveUid.isNotEmpty) return effectiveUid;
    return null;
  }

  ScrollController _performScrollControllerForSelection(int selection) {
    return _scrollControllers.putIfAbsent(
      selection,
      () => _performBuildTrackedScrollController(selection),
    );
  }

  ScrollController _performCurrentScrollController() {
    return scrollControllerForSelection(postSelection.value);
  }

  ScrollPosition? _performCurrentScrollPosition() {
    return _performResolvePrimaryScrollPosition(currentScrollController);
  }

  double _performCurrentScrollOffset() {
    return _performResolvePrimaryScrollPosition(currentScrollController)
            ?.pixels ??
        0;
  }

  Future<void> _performAnimateCurrentSelectionToTop() async {
    final controller = currentScrollController;
    if (!controller.hasClients) return;
    await controller.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _performOnInit() {
    _activeUid = _resolvedActiveUid;
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);

    _performBindCacheWorkers();
    for (final selection in const <int>[0, 1, 2, 3, 4, 5]) {
      scrollControllerForSelection(selection);
    }
    _postSelectionWorker = ever<int>(postSelection, (selection) {
      final controller = scrollControllerForSelection(selection);
      _performSyncScrollToTopVisibility(
        _performResolvePrimaryScrollPosition(controller)?.pixels ?? 0,
      );
      if (selection == 5 &&
          (scheduledPosts.isEmpty || lastScheduledDoc == null)) {
        unawaited(fetchScheduledPosts(isInitial: true));
      }
    });
  }

  void _performOnClose() {
    _authSub?.cancel();
    _resharesSub?.cancel();
    _counterSub?.cancel();
    _persistCacheTimer?.cancel();
    _visibilityDebounce?.cancel();
    _allPostsWorker?.dispose();
    _photosWorker?.dispose();
    _videosWorker?.dispose();
    _resharesWorker?.dispose();
    _scheduledWorker?.dispose();
    _mergedPostsWorker?.dispose();
    _postSelectionWorker?.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
  }

  ScrollController _performBuildTrackedScrollController(int selection) {
    final controller = ScrollController();
    controller.addListener(() {
      if (postSelection.value != selection) return;
      _performSyncScrollToTopVisibility(
        _performResolvePrimaryScrollPosition(controller)?.pixels ?? 0,
      );
    });
    return controller;
  }

  ScrollPosition? _performResolvePrimaryScrollPosition(
    ScrollController controller,
  ) {
    if (!controller.hasClients) return null;
    final positions = controller.positions.toList(growable: false);
    if (positions.isEmpty) return null;
    if (positions.length > 1) {
      _invariantGuard.record(
        surface: 'profile',
        invariantKey: 'multiple_scroll_positions',
        message:
            'Profile scroll controller is attached to more than one scroll position.',
        payload: <String, dynamic>{
          'selection': postSelection.value,
          'positions': positions.length,
        },
      );
    }
    return positions.last;
  }

  void _performSyncScrollToTopVisibility(double offset) {
    final shouldShow = offset > 500;
    if (showScrollToTop.value == shouldShow) {
      return;
    }
    showScrollToTop.value = shouldShow;
  }
}
