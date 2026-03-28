import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/profile_posts_cache_service.dart';
import 'package:turqappv2/Core/Services/slider_cache_service.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';
import 'package:turqappv2/Modules/Splash/splash_startup_orchestrator.dart';

import '../../Core/Repositories/feed_snapshot_repository.dart';
import '../../Core/Repositories/job_home_snapshot_repository.dart';
import '../../Core/Repositories/short_snapshot_repository.dart';
import '../../Core/Services/CacheFirst/cached_resource.dart';
import '../../Modules/Agenda/agenda_controller.dart';
import '../../Modules/NavBar/nav_bar_controller.dart';
import '../../Modules/RecommendedUserList/recommended_user_list_controller.dart';
import '../../Modules/Short/short_controller.dart';
import '../../Modules/Story/StoryRow/story_row_controller.dart';
import '../../Services/user_analytics_service.dart';
import '../../Services/current_user_service.dart';
import '../../Core/Services/network_awareness_service.dart';
import '../../Core/Services/turq_image_cache_manager.dart';
import '../../Core/Repositories/market_snapshot_repository.dart';
import '../../Core/Services/user_profile_cache_service.dart';
import '../../Models/market_item_model.dart';
import '../../main.dart';

part 'splash_view_startup_part.dart';
part 'splash_view_warm_part.dart';
part 'splash_view_intro_part.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  static const Duration _syncStartupMaxWait = Duration(milliseconds: 900);
  static const Duration _syncMinSplashDuration = Duration(milliseconds: 120);
  static const Duration _syncMinLaunchToNavDuration = Duration.zero;
  static const String _splashWord = 'TurqApp';
  static const int _minFeedPostsForNav = 3;
  static const int _minStoryUsersForNav = 1;
  static const int _minShortsForNav = 1;

  bool _minimumStartupPrepared = false;
  bool _feedWarmSnapshotHit = false;
  bool _shortWarmSnapshotHit = false;
  String _feedWarmSnapshotSource = 'none';
  String _shortWarmSnapshotSource = 'none';
  int? _feedWarmSnapshotAgeMs;
  int? _shortWarmSnapshotAgeMs;
  Timer? _startupWatchdogTimer;
  Timer? _typingTimer;
  Timer? _cursorTimer;
  bool _didNavigate = false;
  bool _navigationScheduled = false;
  int _typedLength = 0;
  bool _showCursor = true;
  late final Duration _remainingIntroBudget;

  Duration get _introRevealDuration => Duration(
        milliseconds: IntegrationTestMode.splashIntroMs.clamp(0, 2000),
      );

  @override
  void initState() {
    super.initState();
    final elapsedSinceLaunch = Duration(
      milliseconds: DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
    );
    final remainingMs = (_introRevealDuration.inMilliseconds -
            elapsedSinceLaunch.inMilliseconds)
        .clamp(0, _introRevealDuration.inMilliseconds);
    _remainingIntroBudget = Duration(milliseconds: remainingMs);
    _startTypewriter();

    // Firebase hazır olmadan FirebasePerformance çağrısı yapılmasın.
    unawaited(_initApp());
    final watchdogDuration = IntegrationTestMode.splashWatchdogSeconds > 0
        ? Duration(seconds: IntegrationTestMode.splashWatchdogSeconds)
        : Platform.isIOS
            ? const Duration(seconds: 4)
            : const Duration(seconds: 8);
    _startupWatchdogTimer = Timer(watchdogDuration, () {
      if (!mounted || _didNavigate) return;
      _navigateToPrimaryRoute();

      // Bazı iOS anlarında ilk yönlendirme UI thread yoğunluğunda kaçabiliyor.
      // Kısa aralıklarla birkaç kez daha deneyip beyaz ekranda kalmayı engelle.
      for (final retryMs in <int>[900, 1800, 2800]) {
        Future.delayed(Duration(milliseconds: retryMs), () {
          if (!mounted || _didNavigate) return;
          _navigateToPrimaryRoute();
        });
      }
    });
  }

  Future<void> _initApp() async {
    await _performInitApp();
  }

  Future<void> _navigateToPrimaryRoute() async {
    await _performNavigateToPrimaryRoute();
  }

  Future<void> _runCriticalWarmStartLoads({required bool isFirstLaunch}) async {
    await _performRunCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch);
  }

  Future<void> _runWarmStartLoads({required bool isFirstLaunch}) async {
    await _performRunWarmStartLoads(isFirstLaunch: isFirstLaunch);
  }

  Future<void> _prepareMinimumStartupBeforeNav(
          {required bool isFirstLaunch}) async =>
      _performPrepareMinimumStartupBeforeNav(isFirstLaunch: isFirstLaunch);

  Future<void> _prepareSynchronizedStartupBeforeNav(
          {required bool isFirstLaunch}) async =>
      _performPrepareSynchronizedStartupBeforeNav(isFirstLaunch: isFirstLaunch);

  Future<void> _initCacheProxy() async => _startupOrchestrator.initCacheProxy();

  int _feedWarmPoolLimit() =>
      ContentPolicy.initialPoolLimit(ContentScreenKind.feed);

  @override
  void dispose() {
    _disposeSplashTimers();
    super.dispose();
  }

  void _updateSplashState(VoidCallback fn) {
    setState(fn);
  }

  void _startTypewriter() => _performStartTypewriter();

  @override
  Widget build(BuildContext context) => _buildSplashView(context);
}
