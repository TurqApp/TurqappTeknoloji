part of 'splash_view.dart';

extension _SplashViewStartupPart on _SplashViewState {
  Duration get _firebaseStartupWait => IntegrationTestMode.enabled
      ? const Duration(seconds: 18)
      : const Duration(seconds: 3);

  SplashStartupOrchestrator get _startupOrchestrator =>
      SplashStartupOrchestrator(
        firebaseStartupWait: _firebaseStartupWait,
        isMounted: () => mounted,
        navigateToPrimaryRoute: _navigateToPrimaryRoute,
        prepareSynchronizedStartupBeforeNav:
            ({required isFirstLaunch}) => _prepareSynchronizedStartupBeforeNav(
                  isFirstLaunch: isFirstLaunch,
                ),
        runCriticalWarmStartLoads: ({required isFirstLaunch}) =>
            _runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch),
        runWarmStartLoads: ({required isFirstLaunch}) =>
            _runWarmStartLoads(isFirstLaunch: isFirstLaunch),
        markMinimumStartupPrepared: (value) {
          _minimumStartupPrepared = value;
        },
        isMinimumStartupPrepared: () => _minimumStartupPrepared,
      );

  Future<void> _performInitApp() async => _startupOrchestrator.initializeApp();

  Future<void> _performNavigateToPrimaryRoute() async {
    if (!mounted || _didNavigate || _navigationScheduled) return;
    _navigationScheduled = true;

    final elapsed = Duration(
      milliseconds: DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
    );
    final remaining = _introRevealDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
    if (!mounted || _didNavigate) return;

    var loggedIn = false;
    try {
      loggedIn = CurrentUserService.instance.effectiveUserId.isNotEmpty;
    } catch (_) {
      loggedIn = false;
    }
    if (loggedIn) {
      await _ensureAuthenticatedPrimaryRouteReady();
    }
    final playbackKpi = maybeFindPlaybackKpiService();
    if (playbackKpi != null) {
      playbackKpi.track(
        PlaybackKpiEventType.startup,
        {
          'launchToRouteMs':
              DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
          'loggedIn': loggedIn,
          'minimumStartupPrepared': _minimumStartupPrepared,
          'feedWarmSnapshotHit': _feedWarmSnapshotHit,
          'feedWarmSnapshotSource': _feedWarmSnapshotSource,
          'feedWarmSnapshotAgeMs': _feedWarmSnapshotAgeMs,
          'shortWarmSnapshotHit': _shortWarmSnapshotHit,
          'shortWarmSnapshotSource': _shortWarmSnapshotSource,
          'shortWarmSnapshotAgeMs': _shortWarmSnapshotAgeMs,
        },
      );
      if (loggedIn) {
        unawaited(
          UserAnalyticsService.instance.trackRuntimeHealthSummary(
            surface: 'feed',
            cacheFirst: playbackKpi.summarizeCacheFirst(
              surfaceKeyPrefix: 'feed_',
            ),
            renderDiff: playbackKpi.summarizeRenderDiff(surface: 'feed'),
            playbackWindow: playbackKpi.summarizePlaybackWindow(
              surface: 'feed',
            ),
            extra: <String, dynamic>{
              'launchToRouteMs':
                  DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
              'warmSnapshotHit': _feedWarmSnapshotHit,
              'warmSnapshotSource': _feedWarmSnapshotSource,
              'warmSnapshotAgeMs': _feedWarmSnapshotAgeMs,
            },
          ),
        );
        unawaited(
          UserAnalyticsService.instance.trackRuntimeHealthSummary(
            surface: 'short',
            cacheFirst: playbackKpi.summarizeCacheFirst(
              surfaceKeyPrefix: 'short_',
            ),
            renderDiff: playbackKpi.summarizeRenderDiff(surface: 'short'),
            playbackWindow: playbackKpi.summarizePlaybackWindow(
              surface: 'short',
            ),
            extra: <String, dynamic>{
              'launchToRouteMs':
                  DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
              'warmSnapshotHit': _shortWarmSnapshotHit,
              'warmSnapshotSource': _shortWarmSnapshotSource,
              'warmSnapshotAgeMs': _shortWarmSnapshotAgeMs,
            },
          ),
        );
        unawaited(
          UserAnalyticsService.instance.trackRuntimeHealthSummary(
            surface: 'market',
            cacheFirst: playbackKpi.summarizeCacheFirst(
              surfaceKeyPrefix: 'market_',
            ),
            extra: <String, dynamic>{
              'launchToRouteMs':
                  DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
            },
          ),
        );
        unawaited(
          UserAnalyticsService.instance.trackRuntimeHealthSummary(
            surface: 'jobs',
            cacheFirst: playbackKpi.summarizeCacheFirst(
              surfaceKeyPrefix: 'jobs_',
            ),
            extra: <String, dynamic>{
              'launchToRouteMs':
                  DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
            },
          ),
        );
      }
    }
    _didNavigate = true;
    if (loggedIn) {
      maybeFindNavBarController()?.selectedIndex.value = 0;
      Get.offAll(() => NavBarView());
      return;
    }
    Get.offAll(() => SignIn());
  }

  Future<void> _ensureAuthenticatedPrimaryRouteReady() async {
    try {
      final agendaController = maybeFindAgendaController() ?? ensureAgendaController();
      if (agendaController.agendaList.isNotEmpty) {
        return;
      }
      await agendaController.ensureFeedSurfaceReady().timeout(
        const Duration(milliseconds: 900),
        onTimeout: () {},
      );
    } catch (_) {}
  }

}
