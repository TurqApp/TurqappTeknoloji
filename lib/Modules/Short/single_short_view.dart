import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/short_repository.dart';
import '../../main.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import '../../Models/posts_model.dart';
import '../../Core/Services/global_video_adapter_pool.dart';
import '../../Core/Services/playback_handle.dart';
import '../../Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import '../../Core/Services/integration_test_keys.dart';
import '../../Core/Services/SegmentCache/prefetch_scheduler.dart';
import '../../Core/Services/short_render_coordinator.dart';
import '../../Core/Services/video_state_manager.dart';
import '../../Core/Services/video_telemetry_service.dart';
import '../../Core/Widgets/app_header_action_button.dart';
import '../../Core/Services/SegmentCache/cache_manager.dart';
import 'short_content.dart';
import '../Agenda/FloodListing/flood_listing.dart';

part 'single_short_view_helpers_part.dart';
part 'single_short_view_playback_part.dart';
part 'single_short_view_ui_part.dart';

class MomentumPageScrollPhysics extends PageScrollPhysics {
  const MomentumPageScrollPhysics({
    this.maxPagesPerFling = 1,
    this.baseMinFlingVelocity = 110.0,
    this.fastSwipeFraction = 0.05,
    this.snapPageFraction = 0.05,
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
        mass: 0.35,
        stiffness: 320.0,
        damping: 28.0,
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
  final videoStateManager = VideoStateManager.instance;
  final GlobalVideoAdapterPool _videoPool = GlobalVideoAdapterPool.ensure();
  final ShortRenderCoordinator _shortRenderCoordinator =
      ShortRenderCoordinator.ensure();

  final PageController pageController = PageController();
  int currentPage = 0;
  bool volume = true;
  bool showControls = true;
  DateTime _pageActivatedAt = DateTime.now();
  bool _manualSnapInProgress = false;
  double _manualGestureDragDy = 0.0;
  static const double _manualGestureTriggerDistance = 18.0;
  static const double _manualGestureTriggerVelocity = 80.0;
  static const Duration _engagementRescoreDelay = Duration(milliseconds: 2500);
  static const Duration _progressPersistInterval = Duration(seconds: 2);
  static const double _progressPersistDelta = 0.10;

  /// index → VideoPlayerController
  final Map<int, HLSVideoAdapter> _videoControllers = {};
  final Map<int, VoidCallback> _completionListeners = <int, VoidCallback>{};
  int? _initialIndexForSeek; // initialPosition seek uygulanacak index
  final Set<int> _externallyOwned = <int>{}; // dispose etmeyeceğimiz indexler
  List<PostsModel> _renderedShorts = <PostsModel>[];
  Timer? _engagementRescoreTimer;
  Timer? _fullscreenPlaybackGuardTimer;
  DateTime? _lastProgressPersistAt;
  double _lastPersistedProgress = 0.0;
  bool _telemetryFirstFrame = false;
  HLSVideoAdapter? _telemetryAdapter;
  String? _activeTelemetryVideoId;
  String? _lastExclusivePlayDocId;
  DateTime? _lastExclusivePlayAt;

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
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPop() {
    _handleDidPop();
  }

  @override
  void didPushNext() {
    _handleDidPushNext();
  }

  @override
  void didPopNext() {
    _handleDidPopNext();
  }

  void didStartUserGesture(Route route, Route? previousRoute) {
    _handleDidStartUserGesture();
  }

  void didStopUserGesture() {
    _handleDidStopUserGesture();
  }

  final Map<int, bool> _completionTriggered = {};

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
