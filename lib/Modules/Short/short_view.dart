import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/debug_overlay.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Widgets/Ads/ad_placement_hooks.dart';
import 'package:turqappv2/Services/user_analytics_service.dart';
import 'package:turqappv2/Core/Services/video_telemetry_service.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'short_controller.dart';
import 'short_content.dart';
import '../../Models/posts_model.dart';

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

class ShortView extends StatefulWidget {
  const ShortView({super.key});

  @override
  _ShortViewState createState() => _ShortViewState();
}

class _ShortViewState extends State<ShortView> {
  ShortController get controller => Get.find<ShortController>();

  late PageController pageController;
  int currentPage = 0;
  bool volume = true;
  bool isManuallyPaused = false;
  bool _showOverlayControls = true;
  bool _didInitialAttach = false;
  bool _isTransitioning = false;
  bool _isRefreshing = false;
  bool _manualSnapInProgress = false;
  List<PostsModel> _cachedShorts = [];
  double _manualGestureDragDy = 0.0;
  static const double _manualGestureTriggerDistance = 18.0;
  static const double _manualGestureTriggerVelocity = 80.0;

  // Scroll debounce — hızlı kaydırmada gereksiz adapter oluşturmayı engeller
  Timer? _scrollDebounce;
  Timer? _playDebounce;
  Timer? _tierDebounce;
  Timer? _engagementRescoreTimer;
  static const Duration _playResumeDelay = Duration(milliseconds: 50);
  static const Duration _playResumeDelayAndroid = Duration.zero;
  static const Duration _scrollDebounceAndroid = Duration(milliseconds: 24);
  static const Duration _tierDebounceDelay = Duration(milliseconds: 70);
  static const Duration _engagementRescoreDelay = Duration(milliseconds: 2500);
  static const Duration _progressPersistInterval = Duration(seconds: 2);
  static const double _progressPersistDelta = 0.10;

  DateTime? _lastProgressPersistAt;
  double _lastPersistedProgress = 0.0;

  // A10: Video telemetry — TTFF, buffering, position tracking
  bool _telemetryFirstFrame = false;
  HLSVideoAdapter? _telemetryAdapter;

  // Liste değişimlerini takip eden worker
  Worker? _shortsWorker;

  Future<void> _releasePlayback(HLSVideoAdapter adapter) async {
    if (adapter.isDisposed) return;
    await adapter.forceSilence();
  }

  @override
  void initState() {
    super.initState();
    unawaited(
        UserAnalyticsService.instance.trackFeatureUsage('short_view_open'));

    final initialIndex = controller.shorts.isEmpty
        ? 0
        : controller.lastIndex.value.clamp(0, controller.shorts.length - 1);
    currentPage = initialIndex;
    _cachedShorts = List<PostsModel>.from(controller.shorts);
    pageController = PageController(initialPage: initialIndex);

    // Sadece gerçekten boşsa yükle
    if (controller.shorts.isEmpty) {
      controller.loadInitialShorts().then((_) {
        if (mounted) {
          _cachedShorts = List<PostsModel>.from(controller.shorts);
          setState(() {});
          if (_cachedShorts.isNotEmpty) {
            unawaited(controller.updateCacheTiers(currentPage));
          }
          _startAutoPlayCurrentVideo();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(controller.updateCacheTiers(currentPage));
          _startAutoPlayCurrentVideo();
        }
      });
    }

    // Hedefli reaktivite: RxList değişimlerini debounced setState ile takip et
    _shortsWorker = ever(controller.shorts, (_) {
      if (!mounted) return;
      final newList = List<PostsModel>.from(controller.shorts);
      if (newList.length != _cachedShorts.length) {
        _cachedShorts = newList;
        setState(() {});
      }
    });
  }

  void _onPageChanged(int page) {
    if (_cachedShorts.isEmpty) return;
    if (page == currentPage) return;

    // Eski video'yu hemen durdur (ucuz operasyon)
    final oldVc = controller.cache[currentPage];
    if (oldVc != null) {
      _releasePlayback(oldVc);
      oldVc.removeListener(_videoEndListener);
      oldVc.removeListener(_telemetryListener);
    }

    // A10: Eski video telemetry session'ını bitir
    if (currentPage < _cachedShorts.length) {
      VideoTelemetryService.instance
          .endSession(_cachedShorts[currentPage].docID);
    }

    setState(() {
      currentPage = page;
      _showOverlayControls = true;
    });
    isManuallyPaused = false;
    _isTransitioning = false;
    _telemetryFirstFrame = false;
    _telemetryAdapter = null;

    // Yeni video için progress tracking'i sıfırla
    // Sıfırlanmazsa eski videonun progress değeri delta hesabını bozar
    _lastPersistedProgress = 0.0;
    _lastProgressPersistAt = null;
    _engagementRescoreTimer?.cancel();

    // Pahalı işlemleri debounce ile çalıştır
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(
        defaultTargetPlatform == TargetPlatform.android
            ? _scrollDebounceAndroid
            : const Duration(milliseconds: 60), () {
      if (!mounted) return;

      _enforceSingleActiveAudio(page);
      _schedulePlayForPage(currentPage);

      // Üç katmanlı cache güncellemesi
      _scheduleTierUpdate(currentPage);
      controller.loadMoreIfNeeded(currentPage);
    });
  }

  void _enforceSingleActiveAudio(int activePage) {
    for (final entry in controller.cache.entries) {
      final idx = entry.key;
      final vc = entry.value;
      if (idx == activePage) continue;
      try {
        vc.setVolume(0);
        _releasePlayback(vc);
      } catch (_) {}
    }
  }

  void _scheduleTierUpdate(int page) {
    _tierDebounce?.cancel();
    _tierDebounce = Timer(_tierDebounceDelay, () async {
      await controller.updateCacheTiers(page);
      if (!mounted || page != currentPage) return;
      setState(() {});
      _schedulePlayForPage(page);
    });
  }

  Future<void> _startAutoPlayCurrentVideo() async {
    if (controller.shorts.isEmpty) return;

    isManuallyPaused = false;

    // İlk açılışta warm-start/preload cache'inden gelen diğer adapter'ları
    // bırakıp sadece aktif videoyu tut. Aksi halde aktif video birkaç saniye
    // sonra offscreen adapter akışı tarafından susturulabiliyor.
    await controller.keepOnlyIndex(currentPage);

    // Cache tier'larını güncelle (ilk 5 preload dahil)
    await controller.updateCacheTiers(currentPage);
    if (!mounted) return;
    setState(() {});

    _schedulePlayForPage(currentPage);
  }

  void _schedulePlayForPage(int page) {
    _playDebounce?.cancel();
    _playDebounce = Timer(
        defaultTargetPlatform == TargetPlatform.android
            ? _playResumeDelayAndroid
            : _playResumeDelay, () {
      if (!mounted || page != currentPage) return;
      _enforceSingleActiveAudio(page);
      final vc = controller.cache[page];
      if (vc == null) return;
      vc.setVolume(volume ? 1 : 0);
      if (!vc.value.isPlaying) {
        vc.play();
      }
      _setupVideoEndListener(vc);

      // A10: Telemetry session başlat
      if (page < _cachedShorts.length) {
        final post = _cachedShorts[page];
        VideoTelemetryService.instance
            .startSession(post.docID, post.playbackUrl);
        VideoTelemetryService.instance.updateRuntimeHints(
          post.docID,
          isAudible: volume,
          hasStableFocus: false,
        );
        _telemetryFirstFrame = false;
        _telemetryAdapter = vc;
        vc.addListener(_telemetryListener);
        _scheduleEngagementRescore(page);
      }

      // Cache state machine: playing olarak işaretle
      if (page < _cachedShorts.length) {
        try {
          final cm = Get.find<SegmentCacheManager>();
          cm.markPlaying(_cachedShorts[page].docID);
          // -5 kuralı: gerideki 5 videonun cache'ini koru
          for (var i = 1; i <= 5; i++) {
            final behindIdx = page - i;
            if (behindIdx < 0) break;
            if (behindIdx < _cachedShorts.length) {
              cm.touchEntry(_cachedShorts[behindIdx].docID);
            }
          }
        } catch (_) {}
      }
    });
  }

  void _setupVideoEndListener(HLSVideoAdapter vc) {
    vc.removeListener(_videoEndListener);
    vc.addListener(_videoEndListener);
  }

  void _scheduleEngagementRescore(int page) {
    _engagementRescoreTimer?.cancel();
    _engagementRescoreTimer = Timer(_engagementRescoreDelay, () {
      if (!mounted || page != currentPage || isManuallyPaused) return;
      if (page < 0 || page >= _cachedShorts.length) return;
      final vc = controller.cache[page];
      if (vc == null || !vc.value.hasRenderedFirstFrame) return;
      final docId = _cachedShorts[page].docID;
      VideoTelemetryService.instance.updateRuntimeHints(
        docId,
        isAudible: volume,
        hasStableFocus: true,
      );
      if (Get.isRegistered<PlaybackKpiService>()) {
        Get.find<PlaybackKpiService>().track(
          PlaybackKpiEventType.playbackIntent,
          {
            'source': 'short_view',
            'docId': docId,
            'audible': volume,
            'stableFocus': true,
          },
        );
      }
      try {
        Get.find<PrefetchScheduler>().updateQueue(
          _cachedShorts.map((s) => s.docID).toList(growable: false),
          currentPage,
        );
      } catch (_) {}
    });
  }

  /// A10: HLSVideoAdapter değişimlerini VideoTelemetryService'e iletir.
  void _telemetryListener() {
    final vc = _telemetryAdapter;
    if (vc == null || currentPage >= _cachedShorts.length) return;
    final videoId = _cachedShorts[currentPage].docID;
    final v = vc.value;

    // TTFF: ilk kez playing state'e geçiş
    if (!_telemetryFirstFrame && v.isPlaying) {
      _telemetryFirstFrame = true;
      VideoTelemetryService.instance.onFirstFrame(videoId);
    }

    // Buffering durumu
    if (v.isBuffering) {
      VideoTelemetryService.instance.onBufferingStart(videoId);
    } else if (!v.isBuffering && v.isPlaying) {
      VideoTelemetryService.instance.onBufferingEnd(videoId);
    }

    // Position update
    final pos = v.position.inMilliseconds / 1000.0;
    final dur = v.duration.inMilliseconds / 1000.0;
    if (dur > 0) {
      VideoTelemetryService.instance.onPositionUpdate(videoId, pos, dur);
    }
  }

  void _videoEndListener() {
    if (!mounted || _isTransitioning) return;

    final vc = controller.cache[currentPage];
    if (vc == null) return;

    final position = vc.value.position.inMilliseconds;
    final duration = vc.value.duration.inMilliseconds;

    if (duration > 0 && position > 0) {
      final progress = position / duration;

      // Watch progress'i cache manager'a bildir
      try {
        final now = DateTime.now();
        final shouldPersistByTime = _lastProgressPersistAt == null ||
            now.difference(_lastProgressPersistAt!) >= _progressPersistInterval;
        final shouldPersistByDelta =
            (progress - _lastPersistedProgress).abs() >= _progressPersistDelta;
        final shouldPersist =
            shouldPersistByTime || shouldPersistByDelta || progress >= 0.98;

        if (shouldPersist) {
          Get.find<SegmentCacheManager>().updateWatchProgress(
            _cachedShorts[currentPage].docID,
            progress,
          );
          _lastProgressPersistAt = now;
          _lastPersistedProgress = progress;
        }
      } catch (_) {}

      if (progress >= 0.98) {
        _isTransitioning = true;
        VideoTelemetryService.instance
            .onCompleted(_cachedShorts[currentPage].docID);
        vc.removeListener(_videoEndListener);
        _goToNextVideo();
      }
    }
  }

  void _goToNextVideo() {
    if (currentPage < _cachedShorts.length - 1) {
      final nextPage = currentPage + 1;
      isManuallyPaused = false;
      pageController
          .animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        _isTransitioning = false;
      });
    } else {
      _isTransitioning = false;
    }
  }

  void _handleManualVerticalDragStart(DragStartDetails details) {
    _manualGestureDragDy = 0.0;
  }

  void _handleManualVerticalDragUpdate(DragUpdateDetails details) {
    _manualGestureDragDy += details.primaryDelta ?? 0.0;
  }

  void _handleManualVerticalDragEnd(DragEndDetails details) {
    final delta = _manualGestureDragDy;
    final velocity = details.primaryVelocity ?? 0.0;
    _manualGestureDragDy = 0.0;

    if (!mounted ||
        _manualSnapInProgress ||
        _isTransitioning ||
        _isRefreshing ||
        _cachedShorts.isEmpty) {
      return;
    }

    final goForward = velocity < -_manualGestureTriggerVelocity ||
        delta < -_manualGestureTriggerDistance;
    final goBackward = velocity > _manualGestureTriggerVelocity ||
        delta > _manualGestureTriggerDistance;
    if (goForward == goBackward) return;

    final targetPage = goForward
        ? (currentPage + 1).clamp(0, _cachedShorts.length - 1)
        : (currentPage - 1).clamp(0, _cachedShorts.length - 1);
    if (targetPage == currentPage) return;

    unawaited(_animateManualPage(targetPage));
  }

  Future<void> _animateManualPage(int targetPage) async {
    if (!mounted || _manualSnapInProgress || !pageController.hasClients) return;
    _manualSnapInProgress = true;
    try {
      await pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
    } finally {
      _manualSnapInProgress = false;
    }
  }

  Widget _buildRefreshingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoActivityIndicator(color: Colors.white, radius: 10),
          SizedBox(width: 8),
          Text(
            'Yenileniyor...',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _cachedThumb(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Widget _buildThumbOverlay(String thumb, double modelAr) {
    if (thumb.isEmpty) return const SizedBox.shrink();
    if (modelAr > 1.2) {
      return Center(
        child: AspectRatio(
          aspectRatio: modelAr,
          child: _cachedThumb(thumb),
        ),
      );
    }
    return SizedBox.expand(
      child: _cachedThumb(thumb),
    );
  }

  Widget _buildFullscreenVideoSurface(
    HLSVideoAdapter adapter,
    String keyId, {
    double? modelAspectRatio,
  }) {
    final ar = (modelAspectRatio != null && modelAspectRatio > 0)
        ? modelAspectRatio
        : (9 / 16);

    final player = adapter.buildPlayer(
      key: ValueKey(keyId),
      useAspectRatio: false,
      forceFullscreenOnAndroid: true,
    );

    if (ar > 1.2) {
      return Center(
        child: AspectRatio(
          aspectRatio: ar,
          child: player,
        ),
      );
    }

    return SizedBox.expand(child: player);
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _playDebounce?.cancel();
    _tierDebounce?.cancel();
    _engagementRescoreTimer?.cancel();
    _shortsWorker?.dispose();
    controller.lastIndex.value = currentPage;
    pageController.dispose();

    final vc = controller.cache[currentPage];
    if (vc != null) {
      _releasePlayback(vc);
      vc.removeListener(_videoEndListener);
      vc.removeListener(_telemetryListener);
    }

    // A10: Açık kalan telemetry session'ı bitir
    if (currentPage < _cachedShorts.length) {
      VideoTelemetryService.instance
          .endSession(_cachedShorts[currentPage].docID);
    }

    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    HapticFeedback.mediumImpact();

    try {
      await controller.refreshShorts();
      HapticFeedback.lightImpact();

      currentPage = 0;
      isManuallyPaused = false;
      _isTransitioning = false;
      _cachedShorts = List<PostsModel>.from(controller.shorts);

      if (pageController.hasClients) {
        pageController.jumpToPage(0);
      }

      setState(() {});

      if (controller.shorts.isNotEmpty) {
        _startAutoPlayCurrentVideo();
      }
    } catch (e) {
      // Refresh hatası — sessizce devam et
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obx sadece isRefreshing ve isLoading için — liste reaktivitesi ever() ile
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Obx(() {
          // Sadece bu değerleri oku (hedefli reaktivite)
          final isRefreshingNow = controller.isRefreshing.value;
          final isLoadingNow = controller.isLoading.value;
          final hasMoreNow = controller.hasMore.value;

          final list = _cachedShorts;

          if (list.isEmpty) {
            if (isLoadingNow || hasMoreNow) {
              return const Center(
                child: CupertinoActivityIndicator(color: Colors.white),
              );
            } else {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_library_outlined,
                        color: Colors.white, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Henüz video bulunamadı',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Yeni videolar için daha sonra tekrar deneyin',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              );
            }
          }

          if (currentPage >= list.length) {
            currentPage = list.length - 1;
            if (currentPage < 0) currentPage = 0;
            if (pageController.hasClients) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (pageController.hasClients) {
                  pageController.jumpToPage(currentPage);
                }
              });
            }
          }

          if (!_didInitialAttach) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final desiredIndex = controller.shorts.isEmpty
                  ? 0
                  : controller.lastIndex.value
                      .clamp(0, controller.shorts.length - 1);
              currentPage = desiredIndex;
              try {
                if (pageController.hasClients) {
                  pageController.jumpToPage(desiredIndex);
                }
              } catch (_) {}
            });
            _didInitialAttach = true;
          }

          final pager = GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: _handleManualVerticalDragStart,
            onVerticalDragUpdate: _handleManualVerticalDragUpdate,
            onVerticalDragEnd: _handleManualVerticalDragEnd,
            child: PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, idx) {
                final vp = controller.cache[idx];
                final thumb = list[idx].thumbnail;
                final modelAr = list[idx].aspectRatio > 0
                    ? list[idx].aspectRatio.toDouble()
                    : (9 / 16);

                if (vp == null) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildThumbOverlay(thumb, modelAr),
                      const Center(
                        child: CupertinoActivityIndicator(color: Colors.white),
                      ),
                    ],
                  );
                }

                final isActivePage = idx == currentPage;
                final videoWidget = isActivePage
                    ? _buildFullscreenVideoSurface(
                        vp,
                        'vp-${list[idx].docID}-${vp.hashCode}',
                        modelAspectRatio: modelAr,
                      )
                    : const SizedBox.shrink();

                return RepaintBoundary(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildThumbOverlay(thumb, modelAr),
                      // Video layer
                      if (isActivePage) videoWidget,
                      if (isActivePage)
                        AnimatedBuilder(
                          animation: vp,
                          builder: (_, __) {
                            if (vp.value.hasRenderedFirstFrame) {
                              return const SizedBox.shrink();
                            }
                            return _buildThumbOverlay(thumb, modelAr);
                          },
                        ),
                      if (isActivePage)
                        AnimatedBuilder(
                          animation: vp,
                          builder: (_, __) {
                            if (vp.value.isInitialized) {
                              return const SizedBox.shrink();
                            }
                            return const Center(
                              child: CupertinoActivityIndicator(
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      if (isActivePage)
                        ShortsContent(
                          model: list[idx],
                          isActive: isActivePage,
                          showOverlayControls: _showOverlayControls,
                          onToggleOverlay: () {
                            if (!mounted) return;
                            setState(() {
                              _showOverlayControls = !_showOverlayControls;
                            });
                          },
                          onDoubleTapLike: () async {
                            await PostRepository.ensure().toggleLike(list[idx]);
                          },
                          volumeOff: (v) {
                            if (v) {
                              vp.play();
                              isManuallyPaused = false;
                            } else {
                              vp.pause();
                              isManuallyPaused = true;
                            }
                            if (idx == currentPage) {
                              VideoTelemetryService.instance.updateRuntimeHints(
                                list[idx].docID,
                                isAudible: volume,
                                hasStableFocus: v,
                              );
                            }
                          },
                          videoPlayerController: vp,
                          onEdited: (updatedDocId) async {
                            await controller.updateShort(updatedDocId);
                            await controller.refreshVideoController(idx);
                            setState(() {});
                          },
                        ),
                      // İnce progress bar — altta
                      if (_showOverlayControls && isActivePage)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _ShortProgressBar(adapter: vp),
                        ),
                      if (_showOverlayControls)
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildCircleButton(
                                      icon: CupertinoIcons.arrow_left,
                                      onTap: () => Get.back(),
                                    ),
                                    _buildCircleButton(
                                      icon: volume
                                          ? CupertinoIcons.volume_up
                                          : CupertinoIcons.volume_off,
                                      onTap: () {
                                        setState(() => volume = !volume);
                                        vp.setVolume(volume ? 1 : 0);
                                        if (idx == currentPage) {
                                          VideoTelemetryService.instance
                                              .updateRuntimeHints(
                                            list[idx].docID,
                                            isAudible: volume,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
          final content = currentPage == 0
              ? RefreshIndicator(
                  onRefresh: _handleRefresh,
                  backgroundColor: Colors.transparent,
                  color: Colors.white,
                  strokeWidth: 3.0,
                  displacement: 50.0,
                  child: pager,
                )
              : pager;

          return Stack(
            children: [
              content,
              IgnorePointer(
                ignoring: true,
                child: ShortsAdPlacementHook(index: currentPage),
              ),
              if (isRefreshingNow)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 24,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildRefreshingBadge(),
                  ),
                ),
              if (kDebugMode)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 60,
                  right: 8,
                  child: const CacheDebugOverlay(),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: Colors.black.withAlpha(50), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

/// İnce video progress bar — AnimatedBuilder ile sadece bu widget rebuild olur
class _ShortProgressBar extends StatelessWidget {
  final HLSVideoAdapter adapter;
  const _ShortProgressBar({required this.adapter});

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
