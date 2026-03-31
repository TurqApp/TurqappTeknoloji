part of 'nav_bar_controller.dart';

extension _NavBarControllerSupportFacadePart on NavBarController {
  Future<void> _persistSelectedIndex(int index) =>
      _NavBarControllerSupportPart(this).persistSelectedIndex(index);

  Future<void> _persistStartupRouteHint(int index) =>
      _NavBarControllerSupportPart(this).persistStartupRouteHint(index);
}

class _NavBarControllerSupportPart {
  final NavBarController _controller;

  const _NavBarControllerSupportPart(this._controller);

  String selectedIndexKeyFor(String uid) =>
      '${_selectedIndexPrefKeyPrefix}_$uid';

  int normalizeSelectedIndex(int value) {
    if (value == 2) return 0;
    if (value < 0) return 0;
    if (value > 4) return 4;
    return value;
  }

  Future<void> restorePersistedIndex() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final initialIndex = _controller.selectedIndex.value;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(selectedIndexKeyFor(uid));
      if (stored == null) return;
      if (_controller.selectedIndex.value != initialIndex) {
        await persistStartupRouteHint(_controller.selectedIndex.value);
        return;
      }
      if (initialIndex != 0) {
        await persistStartupRouteHint(initialIndex);
        return;
      }
      _controller.selectedIndex.value = normalizeSelectedIndex(stored);
      await persistStartupRouteHint(_controller.selectedIndex.value);
    } catch (_) {}
  }

  Future<void> persistSelectedIndex(int index) async {
    if (index == 2) return;
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        selectedIndexKeyFor(uid),
        normalizeSelectedIndex(index),
      );
    } catch (_) {}
  }

  Future<void> persistStartupRouteHint(int index) async {
    final uid = CurrentUserService.instance.effectiveUserId.trim();
    if (uid.isEmpty) return;
    try {
      await ensureStartupSnapshotManifestStore().updateRouteHint(
        userId: uid,
        routeHint: routeHintForIndex(index),
        loggedIn: true,
        extra: <String, dynamic>{
          'navSelectedIndex': normalizeSelectedIndex(index),
        },
      );
    } catch (_) {}
  }

  String routeHintForIndex(int index) {
    final normalizedIndex = normalizeSelectedIndex(index);
    final hasEducation =
        maybeFindSettingsController()?.educationScreenIsOn.value ?? false;
    final educationIndex = hasEducation ? 3 : -1;
    final profileIndex = hasEducation ? 4 : 3;

    if (normalizedIndex == 1) return 'nav_explore';
    if (educationIndex >= 0 && normalizedIndex == educationIndex) {
      return 'nav_education';
    }
    if (normalizedIndex == profileIndex) return 'nav_profile';
    return 'nav_feed';
  }

  void handleOnInit() {
    WidgetsBinding.instance.addObserver(_controller);

    _controller.animationController = AnimationController(
      vsync: _controller,
      duration: const Duration(seconds: 10),
    ).obs;
    _controller.animationController.value.repeat();

    _controller.typingController = AnimationController(
      vsync: _controller,
      duration: const Duration(milliseconds: 500),
    ).obs;
    _controller.typingController.value.addListener(() {
      _controller.visibleCharCount.value = (_controller.fullText.length *
              _controller.typingController.value.value)
          .floor();
    });

    _controller.deletingController = AnimationController(
      vsync: _controller,
      duration: const Duration(milliseconds: 700),
    ).obs;
    _controller.deletingController.value.addListener(() {
      _controller.removeCharCount.value =
          (_controller.deletingController.value.value *
                  _controller.fullText.length)
              .floor();
    });

    unawaited(restorePersistedIndex().then((_) async {
      await persistStartupRouteHint(_controller.selectedIndex.value);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller._isDisposed) return;
        final hasEducation =
            maybeFindSettingsController()?.educationScreenIsOn.value ?? false;
        final educationIndex = hasEducation ? 3 : -1;
        final profileIndex = hasEducation ? 4 : 3;
        _controller._primeVisibleSurfaceAfterTabChangeImpl(
          index: _controller.selectedIndex.value,
          educationIndex: educationIndex,
          profileIndex: profileIndex,
        );
        if (_controller.selectedIndex.value == 0) {
          _controller._resumeFeedIfNeededImpl();
        }
      });
    }));
    _controller._runAcilisAnimationImpl();
    Future.delayed(const Duration(seconds: 2), () {
      if (!_controller._isDisposed &&
          !IntegrationTestMode.suppressPeriodicSideEffects) {
        unawaited(_controller._checkAppVersionImpl());
      }
    });
    if (!IntegrationTestMode.suppressPeriodicSideEffects) {
      _controller._scheduleRatingPromptImpl(const Duration(seconds: 25));
    }

    if (!GetPlatform.isIOS &&
        !IntegrationTestMode.suppressPeriodicSideEffects) {
      _controller._startBackgroundCacheLoopImpl();
    }
    _controller._startUploadIndicatorSyncImpl();
  }

  void handleOnClose() {
    _controller._isDisposed = true;
    _controller._backgroundCacheTimer?.cancel();
    _controller._backgroundCacheTimer = null;
    _controller._uploadIndicatorTimer?.cancel();
    _controller._uploadIndicatorTimer = null;
    _controller._ratingPromptTimer?.cancel();
    _controller._ratingPromptTimer = null;
    WidgetsBinding.instance.removeObserver(_controller);

    try {
      _controller.typingController.value.dispose();
    } catch (_) {}

    try {
      _controller.deletingController.value.dispose();
    } catch (_) {}

    try {
      _controller.animationController.value.dispose();
    } catch (_) {}
  }
}
