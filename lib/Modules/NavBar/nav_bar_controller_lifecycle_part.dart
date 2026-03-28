part of 'nav_bar_controller.dart';

extension _NavBarControllerLifecyclePart on NavBarController {
  void _startBackgroundCacheLoopImpl() {
    _backgroundCacheTimer?.cancel();
    _backgroundCacheTimer =
        Timer.periodic(const Duration(seconds: 20), (_) async {
      if (_isDisposed) return;
      if (!ContentPolicy.allowBackgroundRefresh(ContentScreenKind.feed)) {
        return;
      }

      try {
        maybeFindAgendaController()?.ensureFeedCacheWarm();
      } catch (_) {}

      try {
        final shortsController = maybeFindShortController();
        if (shortsController != null && shortsController.shorts.length < 8) {
          shortsController.warmStart(targetCount: 8, maxPages: 2);
        }
      } catch (_) {}

      try {
        final storyController = maybeFindStoryRowController();
        if (storyController != null && storyController.users.length < 30) {
          await storyController.loadStories(
            limit: 30,
            cacheFirst: true,
            silentLoad: true,
          );
        }
      } catch (_) {}
    });
  }

  void _startUploadIndicatorSyncImpl() {
    _uploadIndicatorTimer?.cancel();
    _uploadIndicatorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;
      final queue = UploadQueueService.maybeFind();
      if (queue == null) {
        uploadingPosts.value = false;
        return;
      }
      final stats = queue.getQueueStats();
      final pending = (stats['pending'] as int?) ?? 0;
      final processing = (stats['processing'] as bool?) ?? false;
      uploadingPosts.value = processing || pending > 0;
    });
  }

  Future<void> _runAcilisAnimationImpl() async {
    try {
      if (!_isDisposed) {
        await typingController.value.forward();
      }
      if (!_isDisposed) {
        await Future.delayed(const Duration(seconds: 1));
      }
      if (!_isDisposed) {
        await deletingController.value.forward();
      }
      if (!_isDisposed) {
        hideAcilis.value = true;
      }
    } catch (_) {}
  }

  void _didChangeAppLifecycleStateImpl(AppLifecycleState state) {
    if (_isDisposed) return;
    final hasEducation =
        maybeFindSettingsController()?.educationScreenIsOn.value ?? false;
    final educationIndex = hasEducation ? 3 : -1;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      pauseGlobalTabMedia();
      return;
    }

    if (state == AppLifecycleState.resumed && selectedIndex.value == 0) {
      if (!IntegrationTestMode.suppressPeriodicSideEffects) {
        unawaited(_checkAppVersionImpl());
        _scheduleRatingPromptImpl(const Duration(seconds: 12));
      }
      _resumeFeedIfNeededImpl();
    }

    if (state == AppLifecycleState.resumed &&
        educationIndex >= 0 &&
        selectedIndex.value == educationIndex) {
      try {
        maybeFindEducationController()?.resetActivePasajSurfaceToTop();
      } catch (_) {}
    }
  }

  void _changeIndexImpl(int index) {
    final previous = selectedIndex.value;
    final hasEducation =
        maybeFindSettingsController()?.educationScreenIsOn.value ?? false;
    final educationIndex = hasEducation ? 3 : -1;

    if (index != previous) {
      try {
        FocusManager.instance.primaryFocus?.unfocus();
      } catch (_) {}
      _suspendFeedForTabExitImpl();
      _pauseGlobalTabMediaImpl();
    }

    selectedIndex.value = index;
    unawaited(_persistSelectedIndex(index));

    if (index != previous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        _resetPrimaryTabSurfacesForTransitionImpl(
          educationIndex: educationIndex,
        );
        if (index == 0) {
          _resumeFeedIfNeededImpl();
        }
      });
    }
  }

  void _resetPrimaryTabSurfacesForTransitionImpl({
    required int educationIndex,
  }) {
    try {
      maybeFindAgendaController()?.resetSurfaceForTabTransition();
    } catch (_) {}
    try {
      maybeFindExploreController()?.resetSurfaceForTabTransition();
    } catch (_) {}
    final profile = ProfileController.maybeFind();
    final preserveIntegrationProfileShell =
        IntegrationTestMode.enabled &&
            profile?.postSelection.value ==
                kProfileIntegrationSmokeShellSelection;
    if (!preserveIntegrationProfileShell) {
      try {
        profile?.resetSurfaceForTabTransition();
      } catch (_) {}
    }
    if (educationIndex >= 0) {
      try {
        maybeFindEducationController()?.resetSurfaceForTabTransition();
      } catch (_) {}
    }
  }

  void _pauseGlobalTabMediaImpl() {
    try {
      VideoStateManager.instance.pauseAllVideos(force: true);
    } catch (_) {}
    try {
      AudioFocusCoordinator.instance.pauseAllAudioPlayers();
    } catch (_) {}
  }

  void _suspendFeedForTabExitImpl() {
    final agenda = maybeFindAgendaController();
    if (agenda == null) return;
    final prevIndex = agenda.lastCenteredIndex;
    agenda.lastCenteredIndex = prevIndex;
    agenda.centeredIndex.value = -1;
    agenda.suspendPlaybackForOverlay();
  }

  void _resumeFeedIfNeededImpl() {
    try {
      maybeFindAgendaController()?.resumePlaybackAfterOverlay();
    } catch (_) {}
  }
}
