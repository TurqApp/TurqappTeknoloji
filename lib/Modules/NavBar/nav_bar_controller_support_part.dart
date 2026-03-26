part of 'nav_bar_controller.dart';

extension _NavBarControllerSupportFacadePart on NavBarController {
  Future<void> _persistSelectedIndex(int index) =>
      _NavBarControllerSupportPart(this).persistSelectedIndex(index);
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(selectedIndexKeyFor(uid));
      if (stored == null) return;
      _controller.selectedIndex.value = normalizeSelectedIndex(stored);
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

    unawaited(restorePersistedIndex());
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
