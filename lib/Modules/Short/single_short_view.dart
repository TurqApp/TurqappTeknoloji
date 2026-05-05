import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Widgets/cache_first_network_image.dart';
import '../../main.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import '../../Models/posts_model.dart';
import '../../Core/Services/global_video_adapter_pool.dart';
import '../../Core/Services/playback_handle.dart';
import '../../Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import '../../Core/Services/PlaybackIntelligence/playback_surface_policy.dart';
import '../../Core/Services/feed_diversity_memory_service.dart';
import '../../Core/Services/playback_execution_service.dart';
import '../../Core/Services/integration_test_keys.dart';
import '../../Core/Services/SegmentCache/prefetch_scheduler.dart';
import '../../Core/Services/short_render_coordinator.dart';
import '../../Core/Services/video_telemetry_service.dart';
import '../../Core/Widgets/app_header_action_button.dart';
import '../../Themes/app_tokens.dart';
import 'short_content.dart';
import '../NavBar/nav_bar_controller.dart';
import '../Agenda/FloodListing/flood_listing.dart';
import '../PlaybackRuntime/playback_cache_runtime_service.dart';

part 'single_short_view_helpers_part.dart';
part 'single_short_view_controller_part.dart';
part 'single_short_view_controller_cleanup_part.dart';
part 'single_short_view_controller_bootstrap_part.dart';
part 'single_short_view_controller_listener_part.dart';
part 'single_short_view_controller_sync_part.dart';
part 'single_short_view_playback_part.dart';
part 'single_short_view_ui_part.dart';

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

class SingleShortView extends StatefulWidget {
  /// Tek bir başlangıç videosu
  final PostsModel? startModel;

  /// Başlangıçta kullanacağın bir liste
  final List<PostsModel>? startList;

  /// startModel için başlangıç pozisyonu (Agenda/Classic'den aktarılır)
  final Duration? initialPosition;

  /// startModel için halihazırda initialize edilmiş controller (anında başlatma)
  final HLSVideoAdapter? injectedController;

  const SingleShortView({
    super.key,
    this.startModel,
    this.startList,
    this.initialPosition,
    this.injectedController,
  });

  @override
  _SingleShortViewState createState() => _SingleShortViewState();
}

class _SingleShortViewState extends State<SingleShortView> with RouteAware {
  /// Videoları tutan reaktif liste
  final shorts = <PostsModel>[].obs;
  final PlaybackRuntimeService _playbackRuntimeService =
      const PlaybackRuntimeService();
  final PlaybackExecutionService _playbackExecutionService =
      const PlaybackExecutionService();
  final SegmentCacheRuntimeService _segmentCacheRuntimeService =
      const SegmentCacheRuntimeService();
  final GlobalVideoAdapterPool _videoPool = ensureGlobalVideoAdapterPool();
  final ShortRenderCoordinator _shortRenderCoordinator =
      ensureShortRenderCoordinator();

  final PageController pageController = PageController();
  int currentPage = 0;
  bool volume = true;
  bool showControls = true;
  DateTime _pageActivatedAt = DateTime.now();
  static const Duration _engagementRescoreDelay = Duration(milliseconds: 2500);
  static const Duration _progressPersistInterval = Duration(seconds: 2);
  static const double _progressPersistDelta = 0.10;
  static const Duration _autoplaySegmentGateTimeout =
      Duration(milliseconds: 950);
  static const Duration _autoplaySegmentGatePollInterval =
      Duration(milliseconds: 120);

  /// index → VideoPlayerController
  final Map<int, HLSVideoAdapter> _videoControllers = {};
  final Map<int, VoidCallback> _completionListeners = <int, VoidCallback>{};
  int? _initialIndexForSeek; // initialPosition seek uygulanacak index
  final Set<int> _externallyOwned = <int>{}; // dispose etmeyeceğimiz indexler
  List<PostsModel> _renderedShorts = <PostsModel>[];
  Timer? _engagementRescoreTimer;
  Timer? _fullscreenPlaybackGuardTimer;
  Timer? _autoplaySegmentGateTimer;
  DateTime? _lastProgressPersistAt;
  double _lastPersistedProgress = 0.0;
  DateTime? _autoplaySegmentGateStartedAt;
  bool _autoplaySegmentGateTimedOut = false;
  bool _telemetryFirstFrame = false;
  HLSVideoAdapter? _telemetryAdapter;
  String? _activeTelemetryVideoId;
  String? _lastExclusivePlayDocId;
  DateTime? _lastExclusivePlayAt;
  HLSVideoAdapter? _fullscreenReturnPreservedController;
  bool _forceResumePosterOnReturn = false;
  bool _routeObserverSubscribed = false;
  bool _routePlaybackActive = true;
  String? _suspendedFeedPlaybackHandleKey;

  String _playbackHandleKeyForDoc(String docId) =>
      'single_short:${docId.trim()}';

  String _feedPlaybackHandleKeyForDoc(String docId) => 'feed:${docId.trim()}';

  bool get _isSingleShortRoutePlaybackActive => mounted && _routePlaybackActive;

  PlaybackLifecycleDecision _singleShortPlaybackDecisionFor(
    int page,
    HLSVideoValue value,
  ) {
    if (page < 0 || page >= shorts.length) {
      return const PlaybackLifecycleDecision(
        phase: PlaybackLifecyclePhase.blocked,
        isOwnerCandidate: false,
        hasStableVisualFrame: false,
        shouldHidePoster: false,
        shouldBeAudible: false,
      );
    }
    final docId = shorts[page].docID.trim();
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
    final allowEarlyStableVisual =
        defaultTargetPlatform != TargetPlatform.android;
    final hasVisibleVideoFrame = allowEarlyStableVisual
        ? value.hasRenderedFirstFrame
        : value.hasVisibleVideoFrame;
    final allowStableVisualWithoutPosition =
        allowEarlyStableVisual || hasVisibleVideoFrame;
    return _playbackRuntimeService.evaluateLifecycle(
      PlaybackLifecycleSnapshot(
        docId: _playbackHandleKeyForDoc(docId),
        shouldPlay: isActivePage,
        isSurfacePlaybackAllowed:
            _isSingleShortRoutePlaybackActive && isActivePage,
        isStandalone: true,
        isMuted: !volume,
        requiresReadySegment: true,
        hasReadySegment: _hasReadySingleShortSegment(page),
        isInitialized: value.isInitialized,
        isPlaying: value.isPlaying,
        isBuffering: value.isBuffering,
        isCompleted: value.isCompleted,
        hasRenderedFirstFrame: hasVisibleVideoFrame,
        position: value.position,
        duration: value.duration,
        visualReadyPositionThreshold: allowEarlyStableVisual
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 180),
        allowRenderedFirstFrameAsStableVisual: allowStableVisualWithoutPosition,
      ),
    );
  }

  void _applySingleShortPlaybackPresentation(
      int page, HLSVideoAdapter adapter) {
    final decision = _singleShortPlaybackDecisionFor(page, adapter.value);
    final shouldForceActiveShortAudible = volume &&
        page == currentPage &&
        _isSingleShortRoutePlaybackActive &&
        !adapter.value.isCompleted;
    _playbackExecutionService.applyPresentation(
      adapter,
      shouldBeAudible:
          decision.shouldBeAudible || shouldForceActiveShortAudible,
    );
  }

  Future<void> _reassertSingleShortAudibility(
    int page,
    HLSVideoAdapter adapter,
  ) async {
    if (!mounted ||
        page != currentPage ||
        !_isSingleShortRoutePlaybackActive ||
        adapter.isDisposed) {
      return;
    }
    try {
      await adapter.setVolume(volume ? 1.0 : 0.0);
    } catch (_) {}
    _applySingleShortPlaybackPresentation(page, adapter);
  }

  void _scheduleDelayedSingleShortAudibilityReassert(
    int page,
    HLSVideoAdapter adapter, {
    Duration delay = const Duration(milliseconds: 260),
  }) {
    Future<void>.delayed(delay, () async {
      await _reassertSingleShortAudibility(page, adapter);
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeSingleShortView();
  }

  @override
  void dispose() {
    _disposeSingleShortView();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeObserverSubscribed) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    routeObserver.subscribe(this, route);
    _routeObserverSubscribed = true;
    _routePlaybackActive = route.isCurrent;
  }

  @override
  void didPush() {
    _routePlaybackActive = true;
  }

  @override
  void didPop() {
    _routePlaybackActive = false;
    _handleDidPop();
  }

  @override
  void didPushNext() {
    _routePlaybackActive = false;
    _handleDidPushNext();
  }

  @override
  void didPopNext() {
    _routePlaybackActive = true;
    _handleDidPopNext();
  }

  void didStartUserGesture(Route route, Route? previousRoute) {
    _handleDidStartUserGesture();
  }

  void didStopUserGesture() {
    _handleDidStopUserGesture();
  }

  final Map<int, bool> _completionTriggered = {};

  void _refreshView() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _buildSingleShortView(context);
  }
}

class _SingleShortProgressBar extends StatelessWidget {
  final HLSVideoAdapter adapter;
  const _SingleShortProgressBar({required this.adapter});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: adapter,
      builder: (_, __) {
        final v = adapter.value;
        if (!v.isInitialized || v.duration.inMilliseconds <= 0) {
          return const SizedBox.shrink();
        }
        final progress = v.position.inMilliseconds / v.duration.inMilliseconds;
        return LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 2,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        );
      },
    );
  }
}
