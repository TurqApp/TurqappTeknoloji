part of 'splash_view.dart';

extension _SplashViewStartupPart on _SplashViewState {
  Duration get _firebaseStartupWait => IntegrationTestMode.enabled
      ? const Duration(seconds: 18)
      : const Duration(seconds: 3);

  Future<void> _performInitApp() async {
    final startupStopwatch = Stopwatch()..start();
    try {
      late final SharedPreferences prefs;
      await Future.wait([
        (() async {
          await firebaseBootstrapFuture.timeout(
            _firebaseStartupWait,
            onTimeout: () {},
          );
          await FirestoreConfig.initialize().timeout(
            const Duration(seconds: 2),
            onTimeout: () {},
          );
        })(),
        SharedPreferences.getInstance().then((v) => prefs = v),
        _initAudioContext().catchError((_) {}),
      ]);

      late final bool isFirstLaunch;
      final userService = CurrentUserService.ensure();
      final accountCenter = ensureAccountCenterService();
      await accountCenter.init();

      if (Platform.isIOS) {
        isFirstLaunch = await _handleFirstLaunchAuthCleanup(prefs: prefs)
            .timeout(const Duration(milliseconds: 350), onTimeout: () => false);
        unawaited(userService.initialize());
      } else {
        await Future.wait([
          _handleFirstLaunchAuthCleanup(prefs: prefs)
              .then((v) => isFirstLaunch = v),
          userService.initialize(),
        ]);
      }

      _registerDependencies();
      if (!IntegrationTestMode.skipBackgroundStartupWork) {
        unawaited(_requestTrackingPermission());
        unawaited(_initAdMob(isFirstLaunch: isFirstLaunch));
        unawaited(
          TopTagsRepository.ensure().fetchTrendingTags(
            resultLimit: 30,
            preferCache: false,
            forceRefresh: true,
          ),
        );

        if (userService.effectiveUserId.isNotEmpty) {
          unawaited(MandatoryFollowService.instance.enforceForCurrentUser());
        }
      }

      final loggedIn = userService.effectiveUserId.isNotEmpty;
      if (loggedIn) {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        final currentUser = userService.currentUser;
        if (firebaseUser != null && currentUser != null) {
          unawaited(accountCenter.addCurrentAccount(
            currentUser: currentUser,
            firebaseUser: firebaseUser,
          ));
        }
        if (IntegrationTestMode.deterministicStartup) {
          _minimumStartupPrepared = true;
        } else {
          await _prepareSynchronizedStartupBeforeNav(
            isFirstLaunch: isFirstLaunch,
          );
        }
      }

      if (IntegrationTestMode.skipBackgroundStartupWork) {
        return;
      }
      if (Platform.isIOS) {
        Future.delayed(const Duration(seconds: 3), () {
          unawaited(_backgroundInit(isFirstLaunch: isFirstLaunch));
        });
      } else {
        unawaited(_backgroundInit(isFirstLaunch: isFirstLaunch));
      }
    } catch (_, __) {}

    if (!mounted) return;
    startupStopwatch.stop();
    _navigateToPrimaryRoute();
  }

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
      NavBarController.maybeFind()?.selectedIndex.value = 0;
      Get.offAll(() => NavBarView());
      return;
    }
    Get.offAll(() => SignIn());
  }

  Future<void> _performBackgroundInit({required bool isFirstLaunch}) async {
    try {
      unawaited(_initCacheProxy());

      final loggedIn = CurrentUserService.instance.effectiveUserId.isNotEmpty;
      if (loggedIn) {
        if (!_minimumStartupPrepared) {
          final criticalDelay = Platform.isIOS
              ? Duration.zero
              : Duration(milliseconds: isFirstLaunch ? 250 : 600);
          if (criticalDelay == Duration.zero) {
            unawaited(_runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch));
          } else {
            Future.delayed(criticalDelay, () {
              unawaited(
                _runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch),
              );
            });
          }
        }

        final onWiFi = _isOnWiFiNow();
        Future.delayed(Duration(seconds: isFirstLaunch ? 5 : 8), () {
          if (onWiFi) {
            unawaited(_runWarmStartLoads(isFirstLaunch: isFirstLaunch));
          }
        });
      }

      Future.delayed(const Duration(milliseconds: 900), () {
        unawaited(NotificationService.instance.initialize());
      });
    } catch (_) {}
  }

  Future<void> _initCacheProxy() async {
    if (_SplashViewState._globalCacheProxyReady) return;
    final inFlight = _SplashViewState._globalCacheProxyInitFuture;
    if (inFlight != null) return inFlight;

    final future = _initCacheProxyInternal();
    _SplashViewState._globalCacheProxyInitFuture = future;
    return future;
  }

  Future<void> _initCacheProxyInternal() async {
    try {
      final remote = VideoRemoteConfigService.ensure();
      if (!remote.isReady) {
        await remote.initialize();
      }

      final server = ensureHlsProxyServer(permanent: true);
      if (!server.isStarted) {
        await server.start();
      }

      final cache = SegmentCacheManager.ensure();
      await cache.init();
      await _applyGlobalMediaCacheQuota();

      PrefetchScheduler.ensure(permanent: true);
      _SplashViewState._globalCacheProxyReady = true;
    } catch (_) {
      _SplashViewState._globalCacheProxyReady = false;
    } finally {
      _SplashViewState._globalCacheProxyInitFuture = null;
    }
  }

  Future<void> _applyGlobalMediaCacheQuota() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGb = (prefs.getInt('offline_cache_quota_gb') ?? 3).clamp(3, 6);
      final quotaGb = (savedGb + 1).clamp(4, 7);
      await StorageBudgetManager.maybeFind()?.applyPlanGb(quotaGb);
      final cache = SegmentCacheManager.maybeFind();
      if (cache == null) return;
      await cache.setUserLimitGB(quotaGb);
    } catch (_) {}
  }

  Future<void> _initAudioContext() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _initAdMob({required bool isFirstLaunch}) async {
    try {
      await AdmobUnitConfigService.ensure().init();
      await ensureAdmobBannerWarmupService().warmFromSplash(
        isFirstLaunch: isFirstLaunch,
      );
    } catch (_) {}
  }

  void _registerDependencies() {
    Get.lazyPut(() => NetworkAwarenessService());
    Get.lazyPut(() => OfflineModeService.instance);

    GlobalLoaderController.ensure();
    ensureAdmobBannerWarmupService();
    AdmobUnitConfigService.ensure(permanent: true);
    StoryInteractionOptimizer.ensure();
    Get.lazyPut(() => UnreadMessagesController());
    Get.lazyPut(() => NavBarController());
    Get.lazyPut(() => ProfileController());
    Get.lazyPut(() => AgendaController());
    Get.lazyPut(() => RecommendedUserListController(), fenix: true);
    Get.lazyPut(() => ExploreController());
    Get.lazyPut(() => ShortController());
    Get.lazyPut(() => EducationController());
    Get.lazyPut(() => SavedPostsController());
    Get.lazyPut(() => JobFinderController());
    Get.lazyPut(() => StoryRowController(), fenix: true);
    UploadQueueService.ensure(permanent: true);
    if (!Platform.isIOS) {
      DeepLinkService.ensure();
    }
    IndexPoolStore.ensure(permanent: true);
    ensureUserProfileCacheService();
    StorageBudgetManager.ensure();
    ensurePlaybackPolicyEngine();
    ensurePlaybackKpiService();
  }

  Future<void> _requestTrackingPermission() async {
    return;
  }

  Future<bool> _handleFirstLaunchAuthCleanup({
    required SharedPreferences prefs,
  }) async {
    try {
      const firstLaunchKey = 'app_has_launched_before';

      final hasLaunchedBefore = prefs.getBool(firstLaunchKey) ?? false;
      final isFirstLaunch = !hasLaunchedBefore;
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (!hasLaunchedBefore && firebaseUser != null) {
        await FirebaseAuth.instance.signOut();
        await CurrentUserService.instance.logout();
        await ensureAccountCenterService().signOutAllLocal();
      }

      if (!hasLaunchedBefore) {
        await prefs.setBool(firstLaunchKey, true);
      }
      return isFirstLaunch;
    } catch (_) {
      try {
        await FirebaseAuth.instance.signOut();
        await CurrentUserService.instance.logout();
        await ensureAccountCenterService().signOutAllLocal();
      } catch (_) {}
      return true;
    }
  }
}
