part of 'nav_bar_controller.dart';

extension _NavBarControllerLifecyclePart on NavBarController {
  static const List<Duration> _feedResumeRetryDelaysAfterOverlayPop =
      <Duration>[
    Duration.zero,
    Duration(milliseconds: 120),
    Duration(milliseconds: 320),
    Duration(milliseconds: 650),
  ];
  static const Duration _shortSurfacePrimeDelay = Duration(milliseconds: 420);

  int _asNavStatInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  bool _asNavStatBool(Object? value) {
    if (value is bool) return value;
    final raw = (value ?? '').toString().trim().toLowerCase();
    return raw == 'true' || raw == '1';
  }

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
        if (shortsController != null &&
            selectedIndex.value == 1 &&
            shortsController.shorts.length <
                ReadBudgetRegistry.shortBackgroundWarmTargetCount) {
          shortsController.warmStart(
            targetCount: ReadBudgetRegistry.shortBackgroundWarmTargetCount,
            maxPages: ReadBudgetRegistry.shortBackgroundWarmMaxPages,
          );
        }
      } catch (_) {}

      try {
        final storyController = maybeFindStoryRowController();
        if (storyController != null &&
            selectedIndex.value == 0 &&
            storyController.users.isEmpty) {
          await storyController.loadStories(
            limit: ReadBudgetRegistry.storyInitialLimit,
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
      final pending = _asNavStatInt(stats['pending']);
      final processing = _asNavStatBool(stats['processing']);
      uploadingPosts.value = processing || pending > 0;
    });
  }

  void _cancelShortSurfacePrimeImpl() {
    _shortSurfacePrimeTimer?.cancel();
    _shortSurfacePrimeTimer = null;
  }

  void _scheduleShortSurfacePrimeImpl() {
    _cancelShortSurfacePrimeImpl();
    if (_isDisposed ||
        selectedIndex.value != 0 ||
        IntegrationTestMode.suppressPeriodicSideEffects) {
      return;
    }
    _shortSurfacePrimeTimer = Timer(_shortSurfacePrimeDelay, () async {
      _shortSurfacePrimeTimer = null;
      if (_isDisposed || selectedIndex.value != 0 || mediaOverlayActive) {
        return;
      }
      try {
        final controller = shortCtrl;
        await controller.prepareStartupSurface(
          allowBackgroundRefresh: false,
        );
        if (_isDisposed ||
            selectedIndex.value != 0 ||
            mediaOverlayActive ||
            controller.shorts.isEmpty) {
          return;
        }
        final initialIndex =
            controller.preferredLaunchIndexForCount(controller.shorts.length);
        await controller.ensureActiveAdapterReady(initialIndex);
        final nextIndex = initialIndex + 1;
        if (nextIndex < controller.shorts.length) {
          unawaited(
            controller.prepareNeighborAdapter(initialIndex, nextIndex),
          );
        }
        debugPrint(
          '[ShortAdjacentPrime] status=ready '
          'count=${controller.shorts.length} index=$initialIndex '
          'neighborReady=${nextIndex < controller.shorts.length}',
        );
      } catch (e) {
        debugPrint('[ShortAdjacentPrime] status=error error=$e');
      }
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
    final tabLayout = _primaryTabLayout();

    if (state == AppLifecycleState.paused) {
      _cancelShortSurfacePrimeImpl();
      pauseGlobalTabMedia();
      unawaited(
        _persistCurrentStartupSurfacesImpl(
          includeHomeSurfaces: true,
        ),
      );
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cancelShortSurfacePrimeImpl();
      try {
        AudioFocusCoordinator.instance.pauseAllAudioPlayers();
      } catch (_) {}
      unawaited(
        _persistCurrentStartupSurfacesImpl(
          includeHomeSurfaces: true,
        ),
      );
      return;
    }

    if (state == AppLifecycleState.resumed && selectedIndex.value == 0) {
      if (!IntegrationTestMode.suppressPeriodicSideEffects) {
        unawaited(_checkAppVersionImpl());
        _scheduleRatingPromptImpl(const Duration(seconds: 12));
      }
      _resumeFeedIfNeededImpl();
    }

    if (state == AppLifecycleState.resumed) {
      _primeVisibleSurfaceAfterTabChangeImpl(
        index: selectedIndex.value,
        educationIndex: tabLayout.educationIndex,
        profileIndex: tabLayout.profileIndex,
      );
    }

    if (state == AppLifecycleState.resumed &&
        tabLayout.educationIndex >= 0 &&
        selectedIndex.value == tabLayout.educationIndex) {
      try {
        maybeFindEducationController()?.resetActivePasajSurfaceToTop();
      } catch (_) {}
    }
  }

  void _changeIndexImpl(int index) {
    final previous = selectedIndex.value;
    final tabLayout = _primaryTabLayout();

    if (index != previous) {
      _cancelShortSurfacePrimeImpl();
      try {
        FocusManager.instance.primaryFocus?.unfocus();
      } catch (_) {}
      unawaited(
        _persistStartupSurfacesForIndexImpl(
          previous,
          includeHomeSurfaces: previous == 0,
        ),
      );
      _suspendFeedForTabExitImpl();
      _pauseGlobalTabMediaImpl();
    }

    selectedIndex.value = index;
    unawaited(_persistSelectedIndex(index));
    unawaited(_persistStartupRouteHint(index));

    if (index != previous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        _resetPrimaryTabSurfacesForTransitionImpl(
          educationIndex: tabLayout.educationIndex,
        );
        _primeVisibleSurfaceAfterTabChangeImpl(
          index: index,
          educationIndex: tabLayout.educationIndex,
          profileIndex: tabLayout.profileIndex,
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
    final preserveIntegrationProfileShell = IntegrationTestMode.enabled &&
        profile?.postSelection.value == kProfileIntegrationSmokeShellSelection;
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
    final currentCentered = agenda.centeredIndex.value;
    if (currentCentered >= 0 && currentCentered < agenda.agendaList.length) {
      agenda.lastCenteredIndex = currentCentered;
    }
    agenda.suspendPlaybackForOverlay();
  }

  void _resumeFeedIfNeededImpl() {
    if (mediaOverlayActive) return;
    try {
      maybeFindAgendaController()?.resumePlaybackAfterOverlay();
    } catch (_) {}
  }

  bool _hasFeedPlaybackOwnerImpl() {
    final currentPlaying = VideoStateManager.instance.currentPlayingDocID;
    final key = currentPlaying?.trim() ?? '';
    return key.startsWith('feed:');
  }

  void _cancelFeedResumeRetryImpl({bool invalidateEpoch = true}) {
    _feedResumeRetryTimer?.cancel();
    _feedResumeRetryTimer = null;
    if (invalidateEpoch) {
      _feedResumeRetryEpoch = _feedResumeRetryEpoch + 1;
    }
  }

  void _attemptFeedResumeAfterOverlayPopImpl({
    required int epoch,
    required int attempt,
  }) {
    void runAttempt() {
      if (_isDisposed || epoch != _feedResumeRetryEpoch) return;
      if (mediaOverlayActive || selectedIndex.value != 0) {
        _feedResumeRetryTimer = null;
        return;
      }
      if (_hasFeedPlaybackOwnerImpl()) {
        _feedResumeRetryTimer = null;
        return;
      }

      _resumeFeedIfNeededImpl();
      if (_isDisposed || epoch != _feedResumeRetryEpoch) return;
      if (_hasFeedPlaybackOwnerImpl()) {
        _feedResumeRetryTimer = null;
        return;
      }
      if (attempt + 1 >= _feedResumeRetryDelaysAfterOverlayPop.length) {
        _feedResumeRetryTimer = null;
        return;
      }

      final nextDelay = _feedResumeRetryDelaysAfterOverlayPop[attempt + 1];
      _feedResumeRetryTimer?.cancel();
      _feedResumeRetryTimer = Timer(nextDelay, () {
        _attemptFeedResumeAfterOverlayPopImpl(
          epoch: epoch,
          attempt: attempt + 1,
        );
      });
    }

    if (attempt == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        runAttempt();
      });
      return;
    }
    runAttempt();
  }

  void _scheduleFeedResumeAfterOverlayPopImpl() {
    _cancelFeedResumeRetryImpl();
    final epoch = _feedResumeRetryEpoch;
    _attemptFeedResumeAfterOverlayPopImpl(
      epoch: epoch,
      attempt: 0,
    );
  }

  void _pushMediaOverlayLockImpl() {
    _cancelFeedResumeRetryImpl();
    _mediaOverlayDepth.value = _mediaOverlayDepth.value + 1;
    _suspendFeedForTabExitImpl();
    _pauseGlobalTabMediaImpl();
  }

  void _popMediaOverlayLockImpl() {
    final next = _mediaOverlayDepth.value - 1;
    _mediaOverlayDepth.value = next < 0 ? 0 : next;
    if (mediaOverlayActive) return;
    _scheduleFeedResumeAfterOverlayPopImpl();
  }

  void _primeVisibleSurfaceAfterTabChangeImpl({
    required int index,
    required int educationIndex,
    required int profileIndex,
  }) {
    if (index == 0) {
      unawaited(maybeFindAgendaController()?.onPrimarySurfaceVisible());
      _scheduleShortSurfacePrimeImpl();
      return;
    }
    _cancelShortSurfacePrimeImpl();
    if (index == 1) {
      unawaited(maybeFindExploreController()?.onPrimarySurfaceVisible());
      return;
    }
    if (educationIndex >= 0 && index == educationIndex) {
      final activeEducationTabId =
          maybeFindEducationController()?.currentPasajTabId();
      if (activeEducationTabId == PasajTabIds.market) {
        unawaited(maybeFindMarketController()?.onPrimarySurfaceVisible());
        return;
      }
      if (activeEducationTabId == PasajTabIds.jobFinder) {
        unawaited(maybeFindJobFinderController()?.onPrimarySurfaceVisible());
      }
      return;
    }
    if (index == profileIndex) {
      unawaited(ProfileController.maybeFind()?.onPrimarySurfaceVisible());
    }
  }

  Future<void> _persistCurrentStartupSurfacesImpl({
    required bool includeHomeSurfaces,
  }) {
    return _persistStartupSurfacesForIndexImpl(
      selectedIndex.value,
      includeHomeSurfaces: includeHomeSurfaces,
    );
  }

  Future<void> _persistStartupSurfacesForIndexImpl(
    int index, {
    required bool includeHomeSurfaces,
  }) async {
    final normalizedIndex = index < 0 ? 0 : index;
    final tabLayout = _primaryTabLayout();

    final tasks = <Future<void>>[];
    if (includeHomeSurfaces || normalizedIndex == 0) {
      final agenda = maybeFindAgendaController();
      if (agenda != null) {
        tasks.add(agenda.persistStartupShard());
      }
      final shorts = maybeFindShortController();
      if (shorts != null) {
        tasks.add(shorts.persistStartupShard());
      }
    }

    if (normalizedIndex == 1) {
      final explore = maybeFindExploreController();
      if (explore != null) {
        tasks.add(explore.persistStartupShard());
      }
    } else if (tabLayout.educationIndex >= 0 &&
        normalizedIndex == tabLayout.educationIndex) {
      final activeEducationTabId =
          maybeFindEducationController()?.currentPasajTabId();
      if (activeEducationTabId == PasajTabIds.market) {
        final market = maybeFindMarketController();
        if (market != null) {
          tasks.add(market.persistStartupShard());
        }
      } else if (activeEducationTabId == PasajTabIds.jobFinder) {
        final jobs = maybeFindJobFinderController();
        if (jobs != null) {
          tasks.add(jobs.persistStartupShard());
        }
      }
    } else if (normalizedIndex == tabLayout.profileIndex) {
      final profile = ProfileController.maybeFind();
      if (profile != null) {
        tasks.add(profile.persistStartupShard());
      }
    }

    if (tasks.isEmpty) return;
    await Future.wait(tasks, eagerError: false);
  }
}
