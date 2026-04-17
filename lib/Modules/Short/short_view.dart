import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Services/SegmentCache/debug_overlay.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/feed_diversity_memory_service.dart';
import 'package:turqappv2/Core/Services/playback_execution_service.dart';
import 'package:turqappv2/Core/Services/qa_lab_bridge.dart';
import 'package:turqappv2/Core/Services/short_render_coordinator.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Core/Widgets/Ads/ad_placement_hooks.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Services/user_analytics_service.dart';
import 'package:turqappv2/Core/Services/video_telemetry_service.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/PlaybackRuntime/playback_cache_runtime_service.dart';
import '../../main.dart';
import 'short_controller.dart';
import 'short_content.dart';
import '../../Models/posts_model.dart';
import '../../Services/post_interaction_service.dart';

part 'short_view_playback_part.dart';
part 'short_view_ui_part.dart';

const Duration _shortPlayResumeDelay = Duration(milliseconds: 50);
const Duration _shortPlayResumeDelayAndroid = Duration.zero;
const Duration _shortScrollDebounceAndroid = Duration(milliseconds: 24);
const Duration _shortTierDebounceDelay = Duration(milliseconds: 70);
const Duration _shortTierReconcileDelay = Duration(milliseconds: 220);
const Duration _shortEngagementRescoreDelay = Duration(milliseconds: 2500);
const Duration _shortPlayWatchdogDelayAndroid = Duration(milliseconds: 450);
const Duration _shortPlayWatchdogDelayIOS = Duration(milliseconds: 900);
const Duration _shortProgressPersistInterval = Duration(seconds: 2);
const double _shortProgressPersistDelta = 0.10;

class MomentumPageScrollPhysics extends PageScrollPhysics {
  const MomentumPageScrollPhysics({
    this.maxPagesPerFling = 1,
    this.baseMinFlingVelocity = 92.0,
    this.fastSwipeFraction = 0.035,
    this.snapPageFraction = 0.035,
    super.parent,
  });

  final int maxPagesPerFling;
  final double baseMinFlingVelocity;
  final double fastSwipeFraction;
  final double snapPageFraction;

  @override
  MomentumPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return MomentumPageScrollPhysics(
      maxPagesPerFling: maxPagesPerFling,
      baseMinFlingVelocity: baseMinFlingVelocity,
      fastSwipeFraction: fastSwipeFraction,
      snapPageFraction: snapPageFraction,
      parent: buildParent(ancestor),
    );
  }

  @override
  double get minFlingVelocity => baseMinFlingVelocity;

  @override
  double get minFlingDistance => 8.0;

  @override
  double get dragStartDistanceMotionThreshold => 2.0;

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.28,
        stiffness: 420.0,
        damping: 24.0,
      );

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent) ||
        position.viewportDimension <= 0) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final page = position.pixels / position.viewportDimension;
    final minPage = position.minScrollExtent / position.viewportDimension;
    final maxPage = position.maxScrollExtent / position.viewportDimension;
    final floorPage = page.floorToDouble();
    final ceilPage = page.ceilToDouble();
    final progressFromFloor = page - floorPage;
    final progressFromCeil = ceilPage - page;

    double targetPage =
        progressFromFloor >= snapPageFraction ? floorPage + 1 : floorPage;
    if (velocity.abs() >= baseMinFlingVelocity) {
      int pagesToAdvance = 1;
      if (velocity.abs() > baseMinFlingVelocity * 2.0) pagesToAdvance = 2;
      if (velocity.abs() > baseMinFlingVelocity * 3.2) {
        pagesToAdvance = maxPagesPerFling;
      }

      targetPage = velocity > 0
          ? (page.ceilToDouble() + (pagesToAdvance - 1))
          : (page.floorToDouble() - (pagesToAdvance - 1));
    } else if (velocity > tolerance.velocity) {
      targetPage =
          progressFromFloor >= fastSwipeFraction ? floorPage + 1 : floorPage;
    } else if (velocity < -tolerance.velocity) {
      targetPage =
          progressFromCeil >= fastSwipeFraction ? ceilPage - 1 : ceilPage;
    }

    final targetPixels =
        targetPage.clamp(minPage, maxPage) * position.viewportDimension;

    if ((targetPixels - position.pixels).abs() < tolerance.distance) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: tolerance,
    );
  }
}

class ShortView extends StatefulWidget {
  const ShortView({super.key});

  @override
  _ShortViewState createState() => _ShortViewState();
}

class _ShortViewState extends State<ShortView> with RouteAware {
  ShortController get controller => ensureShortController();
  final ShortRenderCoordinator _shortRenderCoordinator =
      ensureShortRenderCoordinator();
  final PlaybackRuntimeService _playbackRuntimeService =
      const PlaybackRuntimeService();
  final PlaybackExecutionService _playbackExecutionService =
      const PlaybackExecutionService();
  final SegmentCacheRuntimeService _segmentCacheRuntimeService =
      const SegmentCacheRuntimeService();

  late PageController pageController;
  int currentPage = 0;
  bool volume = true;
  bool isManuallyPaused = false;
  bool _showOverlayControls = true;
  bool _didInitialAttach = false;
  bool _didPrimeInitialPlayback = false;
  bool _startupPlaybackSettled = false;
  bool _isTransitioning = false;
  String? _lastExclusivePlayDocId;
  DateTime? _lastExclusivePlayAt;
  String? _lastPrimaryPlayDocId;
  DateTime? _lastPrimaryPlayAt;
  String? _lastShortPlaybackAttemptToken;
  DateTime? _lastShortPlaybackAttemptAt;
  String? _lastAutoplayBootstrapToken;
  DateTime? _lastAutoplayBootstrapAt;
  String _currentScrollToken = '';
  String _lastReportedStableFrameToken = '';
  String? _pendingActiveAdapterEnsureToken;
  int? _pendingPlayPage;
  String? _pendingPlayDocId;
  bool _pendingPageActivation = false;
  bool _forceResumePosterOnReturn = false;
  int? _pendingAutoAdvancePage;
  int? _preparedAutoAdvancePage;
  List<PostsModel>? _pendingStartupRenderList;
  List<PostsModel> _cachedShorts = [];
  final Set<String> _recordedVisibleShortDocIds = <String>{};

  // Scroll debounce — hızlı kaydırmada gereksiz adapter oluşturmayı engeller
  Timer? _scrollDebounce;
  Timer? _playDebounce;
  Timer? _tierDebounce;
  Timer? _tierReconcileDebounce;
  Timer? _engagementRescoreTimer;
  Timer? _playbackWatchdogTimer;
  Timer? _routeVisiblePlaybackBootstrapTimer;
  Duration _playbackWatchdogBaselinePosition = Duration.zero;
  DateTime? _autoplaySegmentGateStartedAt;
  bool _autoplaySegmentGateTimedOut = false;

  DateTime? _lastProgressPersistAt;
  double _lastPersistedProgress = 0.0;

  // A10: Video telemetry — TTFF, buffering, position tracking
  bool _telemetryFirstFrame = false;
  HLSVideoAdapter? _telemetryAdapter;
  int _playWatchdogRetries = 0;
  Timer? _stallWatchdogTimer;
  Timer? _iosNativePlaybackGuardTimer;
  Duration _stallWatchdogLastPosition = Duration.zero;
  int _stallWatchdogRetries = 0;
  int _stallWatchdogBufferingCycles = 0;
  bool _routeObserverSubscribed = false;
  static const Duration _shortAutoplaySegmentGateTimeout =
      Duration(milliseconds: 420);
  static const Duration _shortAutoplaySegmentGatePollInterval =
      Duration(milliseconds: 80);

  // Liste değişimlerini takip eden worker
  Worker? _shortsWorker;

  int _initialDisplayIndex(List<PostsModel> list, int rawIndex) {
    if (list.isEmpty) return 0;
    return rawIndex.clamp(0, list.length - 1);
  }

  bool get _isShortRoutePlaybackActive {
    if (!mounted) return false;
    return ModalRoute.of(context)?.isCurrent ?? true;
  }

  PlaybackLifecycleDecision _shortPlaybackDecisionFor(
    int page,
    HLSVideoValue value,
  ) {
    final post =
        page >= 0 && page < _cachedShorts.length ? _cachedShorts[page] : null;
    final docId = post?.docID.trim() ?? '';
    if (docId.isEmpty) {
      return const PlaybackLifecycleDecision(
        phase: PlaybackLifecyclePhase.blocked,
        isOwnerCandidate: false,
        hasStableVisualFrame: false,
        shouldHidePoster: false,
        shouldBeAudible: false,
      );
    }
    final isActivePage = page == currentPage;
    return _playbackRuntimeService.evaluateLifecycle(
      PlaybackLifecycleSnapshot(
        docId: controller.playbackHandleKeyForDoc(docId),
        shouldPlay: isActivePage && !isManuallyPaused,
        isSurfacePlaybackAllowed: _isShortRoutePlaybackActive && isActivePage,
        isStandalone: false,
        isMuted: !volume,
        requiresReadySegment: true,
        hasReadySegment: _hasReadyShortSegment(page),
        isInitialized: value.isInitialized,
        isPlaying: value.isPlaying,
        isBuffering: value.isBuffering,
        isCompleted: value.isCompleted,
        hasRenderedFirstFrame: value.hasRenderedFirstFrame,
        position: value.position,
        duration: value.duration,
        visualReadyPositionThreshold: const Duration(milliseconds: 90),
      ),
    );
  }

  void _applyShortPlaybackPresentation(int page, HLSVideoAdapter adapter) {
    final decision = _shortPlaybackDecisionFor(page, adapter.value);
    final shouldForceActiveShortAudible = volume &&
        page == currentPage &&
        _isShortRoutePlaybackActive &&
        !isManuallyPaused &&
        !adapter.value.isCompleted;
    _playbackExecutionService.applyPresentation(
      adapter,
      shouldBeAudible:
          decision.shouldBeAudible || shouldForceActiveShortAudible,
    );
  }

  void _scheduleRouteVisiblePlaybackBootstrap({
    Duration delay = const Duration(milliseconds: 240),
  }) {
    _routeVisiblePlaybackBootstrapTimer?.cancel();
    _routeVisiblePlaybackBootstrapTimer = Timer(delay, () {
      if (!mounted || !_isShortRoutePlaybackActive || _cachedShorts.isEmpty) {
        return;
      }
      _startAutoPlayCurrentVideo();
    });
  }

  void _scheduleInitialRoutePlaybackBootstrapIfNeeded() {
    if (_didInitialAttach) return;
    _didInitialAttach = true;
    if (_cachedShorts.isEmpty) {
      return;
    }
    _scheduleRouteVisiblePlaybackBootstrap(delay: Duration.zero);
  }

  Future<void> _releasePlayback(HLSVideoAdapter adapter) async {
    if (adapter.isDisposed) return;
    await _playbackExecutionService.stopAdapter(adapter);
  }

  void _primeInitialPlayback() {
    if (_didPrimeInitialPlayback) return;
    _didPrimeInitialPlayback = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isShortRoutePlaybackActive) return;
      _startAutoPlayCurrentVideo();
    });
  }

  void _syncShortSurfaceAfterStartup() {
    if (!mounted) return;
    final nextList = List<PostsModel>.from(controller.shorts);
    if (_cachedShorts.isEmpty) {
      _cachedShorts = nextList;
      currentPage = _initialDisplayIndex(_cachedShorts, currentPage);
      controller.lastIndex.value = currentPage;
      if (pageController.hasClients) {
        try {
          pageController.jumpToPage(currentPage);
        } catch (_) {}
      }
      setState(() {});
    } else {
      _applyRenderListUpdate(nextList);
    }
    if (_cachedShorts.isNotEmpty && _isShortRoutePlaybackActive) {
      unawaited(controller.ensureActiveAdapterReady(currentPage));
      _primeInitialPlayback();
    }
  }

  Future<void> _pauseCurrentShortRoutePlayback() async {
    _scrollDebounce?.cancel();
    _playDebounce?.cancel();
    _tierDebounce?.cancel();
    _tierReconcileDebounce?.cancel();
    _engagementRescoreTimer?.cancel();
    _playbackWatchdogTimer?.cancel();
    _stallWatchdogTimer?.cancel();
    _iosNativePlaybackGuardTimer?.cancel();
    _lastPrimaryPlayDocId = null;
    _lastPrimaryPlayAt = null;
    final vc = controller.cache[currentPage];
    if (vc != null) {
      _persistShortPlaybackState(currentPage, vc);
      await _releasePlayback(vc);
      vc.removeListener(_videoEndListener);
      vc.removeListener(_telemetryListener);
    }
    if (currentPage < _cachedShorts.length) {
      await VideoTelemetryService.instance.endSession(
        _cachedShorts[currentPage].docID,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(
        UserAnalyticsService.instance.trackFeatureUsage('short_view_open'));
    try {
      maybeFindNavBarController()?.pushMediaOverlayLock();
      maybeFindNavBarController()?.suspendFeedForTabExit();
      maybeFindNavBarController()?.pauseGlobalTabMedia();
    } catch (_) {}
    try {
      AudioFocusCoordinator.instance.pauseAllAudioPlayers();
    } catch (_) {}
    try {
      _playbackRuntimeService.pauseAll(force: true);
    } catch (_) {}

    final initialIndex = controller.shorts.isEmpty
        ? 0
        : _initialDisplayIndex(
            controller.shorts,
            controller.lastIndex.value,
          );
    currentPage = initialIndex;
    controller.lastIndex.value = currentPage;
    _cachedShorts = List<PostsModel>.from(controller.shorts);
    pageController = PageController(initialPage: initialIndex);
    controller.onPrimarySurfaceVisible().then((_) {
      _syncShortSurfaceAfterStartup();
    }).catchError((_) {
      _syncShortSurfaceAfterStartup();
    });

    // Hedefli reaktivite: RxList değişimlerini debounced setState ile takip et
    _shortsWorker = ever(controller.shorts, (_) {
      if (!mounted) return;
      final newList = List<PostsModel>.from(controller.shorts);
      _applyRenderListUpdate(newList);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeObserverSubscribed) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    routeObserver.subscribe(this, route);
    _routeObserverSubscribed = true;
    if (route.isCurrent) {
      _scheduleInitialRoutePlaybackBootstrapIfNeeded();
    }
  }

  @override
  void didPush() {
    _scheduleInitialRoutePlaybackBootstrapIfNeeded();
  }

  @override
  void didPushNext() {
    _forceResumePosterOnReturn = false;
    unawaited(_pauseCurrentShortRoutePlayback());
  }

  @override
  void didPopNext() {
    final isStillCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isStillCurrent) return;
    try {
      maybeFindNavBarController()?.suspendFeedForTabExit();
      maybeFindNavBarController()?.pauseGlobalTabMedia();
    } catch (_) {}
    if (_cachedShorts.isEmpty) return;
    _forceResumePosterOnReturn = true;
    _scheduleRouteVisiblePlaybackBootstrap(delay: Duration.zero);
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _playDebounce?.cancel();
    _tierDebounce?.cancel();
    _tierReconcileDebounce?.cancel();
    _engagementRescoreTimer?.cancel();
    _playbackWatchdogTimer?.cancel();
    _routeVisiblePlaybackBootstrapTimer?.cancel();
    _stallWatchdogTimer?.cancel();
    _iosNativePlaybackGuardTimer?.cancel();
    _shortsWorker?.dispose();
    if (_routeObserverSubscribed) {
      try {
        routeObserver.unsubscribe(this);
      } catch (_) {}
      _routeObserverSubscribed = false;
    }
    controller.lastIndex.value = currentPage;
    pageController.dispose();

    final vc = controller.cache[currentPage];
    if (vc != null) {
      _persistShortPlaybackState(currentPage, vc);
      _releasePlayback(vc);
      vc.removeListener(_videoEndListener);
      vc.removeListener(_telemetryListener);
    }

    // A10: Açık kalan telemetry session'ı bitir
    if (currentPage < _cachedShorts.length) {
      VideoTelemetryService.instance
          .endSession(_cachedShorts[currentPage].docID);
    }
    try {
      maybeFindNavBarController()?.popMediaOverlayLock();
      _playbackRuntimeService.exitExclusiveMode();
    } catch (_) {}

    super.dispose();
  }

  void _updateShortViewState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  Widget build(BuildContext context) => _buildShortView(context);
}
