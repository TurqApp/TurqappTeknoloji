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
import '../../Core/Services/SegmentCache/prefetch_scheduler.dart';
import '../../Core/Services/short_render_coordinator.dart';
import '../../Core/Services/video_state_manager.dart';
import '../../Core/Services/video_telemetry_service.dart';
import '../../Core/Widgets/app_header_action_button.dart';
import '../../Core/Services/SegmentCache/cache_manager.dart';
import 'short_content.dart';
import '../Agenda/FloodListing/flood_listing.dart';

part 'single_short_view_helpers_part.dart';

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
    // Feed'den aynı controller enjekte edildiyse geçişte pause etme;
    // aksi halde arka plandaki videoları sustur.
    final hasInjectedPlayingController = widget.injectedController != null &&
        !widget.injectedController!.isDisposed &&
        widget.injectedController!.value.isInitialized;
    if (!hasInjectedPlayingController) {
      try {
        VideoStateManager.instance.pauseAllVideos(force: true);
      } catch (_) {}
    }

    // Page değişimini PageView.onPageChanged ile yöneteceğiz

    // Enjekte edilmiş controller varsa, daha "shorts" seed olmadan ilk frame'i hazırlayalım
    // injectedController eşlemesini, liste ve initial index kesinleşince yapıyoruz

    // Hızlı başlangıç: ekrandaki videoyu anında göstermek için listeyi seed et
    if (widget.startList != null && widget.startList!.isNotEmpty) {
      final merged = <PostsModel>[];
      if (widget.startModel != null &&
          widget.startList!.every((p) => p.docID != widget.startModel!.docID)) {
        merged.add(widget.startModel!);
      }
      merged.addAll(widget.startList!);
      shorts.assignAll(merged);
      _configureInitialForList(merged);
    } else if (widget.startModel != null) {
      final merged = <PostsModel>[widget.startModel!];
      shorts.assignAll(merged);
      _configureInitialForList(merged);
    }

    // Liste her değiştiğinde önceki player'ları temizle, sıfırla, preload
    ever<List<PostsModel>>(shorts, _handleShortsChange);

    // İlk yükleme: startList verilmişse fetch yapma; akış için mevcut listeleri kullan
    final shouldFetch = widget.startList == null || widget.startList!.isEmpty;
    if (shouldFetch) {
      // Firestore’dan al, shuffle et, startModel/startList’i başa koy
      _fetchAndShuffle();
    }
  }

  void _onPageChanged(int page) {
    if (page == currentPage) return;

    // 1) Önceki videoyu durdur
    final prev = _videoControllers[currentPage];
    if (prev != null) {
      try {
        _releasePlayback(prev);
      } catch (_) {}
    }
    unawaited(_endActiveTelemetrySession());

    // 2) Yeni sayfayı ata
    currentPage = page;
    showControls = true;
    _pageActivatedAt = DateTime.now();
    if (currentPage >= 0 && currentPage < shorts.length) {
      try {
        VideoStateManager.instance
            .updateExclusiveModeDoc(shorts[currentPage].docID);
      } catch (_) {}
    }

    // Yarış koşullarını azalt: yeni sayfa dışında tüm controller'ları durdur.
    for (final entry in _videoControllers.entries) {
      if (entry.key == currentPage) continue;
      try {
        _releasePlayback(entry.value);
      } catch (_) {}
    }

    // Yeni sayfaya geçildiğinde completion flag'ini resetle
    _completionTriggered[page] = false;

    // 3) İlk video geçişinden sonra injected controller'ı artık kullanma
    if (_initialIndexForSeek != null && page != _initialIndexForSeek) {
      _initialIndexForSeek =
          null; // Reset et ki injected controller tekrar kullanılmasın
    }

    // 4) Yeni videoyu hazırla ve oynat
    _ensureController(currentPage);
    final vp = _videoControllers[currentPage];

    // Injected controller map dışında kaldıysa bile offscreen durumda zorla durdur.
    final injected = widget.injectedController;
    if (injected != null && (vp == null || !identical(injected, vp))) {
      try {
        _releasePlayback(injected);
      } catch (_) {}
    }

    if (vp != null) {
      if (vp.isDisposed) return;
      _primePlaybackForIndex(currentPage);

      // Cache state machine: playing olarak işaretle
      if (currentPage < shorts.length) {
        try {
          final cm = Get.find<SegmentCacheManager>();
          cm.markPlaying(shorts[currentPage].docID);
          // -5 kuralı: gerideki 5 videonun cache'ini koru
          for (var i = 1; i <= 5; i++) {
            final behindIdx = currentPage - i;
            if (behindIdx < 0) break;
            if (behindIdx < shorts.length) {
              cm.touchEntry(shorts[behindIdx].docID);
            }
          }
        } catch (_) {}
      }
    }
    // 5) +5/-5 aralığı preload & dışındakileri dispose et
    _preloadRange(currentPage);
    _disposeOutsideRange(currentPage);
    setState(() {});
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

    if (!mounted || _manualSnapInProgress || shorts.isEmpty) return;

    final goForward = velocity < -_manualGestureTriggerVelocity ||
        delta < -_manualGestureTriggerDistance;
    final goBackward = velocity > _manualGestureTriggerVelocity ||
        delta > _manualGestureTriggerDistance;
    if (goForward == goBackward) return;

    final targetPage = goForward
        ? (currentPage + 1).clamp(0, shorts.length - 1)
        : (currentPage - 1).clamp(0, shorts.length - 1);
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

  @override
  void dispose() {
    try {
      final route = ModalRoute.of(context);
      if (route != null) routeObserver.unsubscribe(this);
    } catch (_) {}
    // Not: _onPageChanged, PageView.onPageChanged üzerinden kullanılıyor;
    // pageController.addListener ile eklenmediği için removeListener çağrısı gereksiz ve hataya yol açıyor.
    pageController.dispose();
    unawaited(_endActiveTelemetrySession());
    _clearAllControllers();
    try {
      VideoStateManager.instance.exitExclusiveMode();
    } catch (_) {}
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
    // Bu sayfadan çıkılıyor: VideoStateManager'a pozisyonu kaydet
    try {
      if (currentPage >= 0 && currentPage < shorts.length) {
        final currentModel = shorts[currentPage];
        final ctrl = _videoControllers[currentPage];

        if (ctrl != null && ctrl.value.isInitialized) {
          // VideoStateManager'a kaydet
          final videoStateManager = Get.find<VideoStateManager>();
          videoStateManager.saveVideoState(
            currentModel.docID,
            HLSAdapterPlaybackHandle(ctrl),
          );
        }
      }
    } catch (_) {}

    // Tüm videoları durdur
    unawaited(_endActiveTelemetrySession());
    _pauseAllControllers();
    try {
      VideoStateManager.instance.exitExclusiveMode();
    } catch (_) {}
  }

  @override
  void didPushNext() {
    unawaited(_endActiveTelemetrySession());
    unawaited(_pauseAllControllers());
  }

  @override
  void didPopNext() {
    final isStillCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isStillCurrent) return;
    if (currentPage < 0 || currentPage >= shorts.length) return;

    final vp = _videoControllers[currentPage];
    if (vp == null || vp.isDisposed) return;

    try {
      VideoStateManager.instance.enterExclusiveMode(shorts[currentPage].docID);
    } catch (_) {}
    _primePlaybackForIndex(currentPage);
  }

  void didStartUserGesture(Route route, Route? previousRoute) {
    // iOS interaktif geri kaydirma basladiginda: hemen tum sesleri durdur
    _pauseAllControllers();
  }

  void didStopUserGesture() {
    // Geri kaydirma iptal edildiyse (sayfa hala en ustteyse) oynatmayi geri getir
    final isStillCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (isStillCurrent) {
      final vp = _videoControllers[currentPage];
      if (vp != null && vp.value.isInitialized) {
        try {
          if (vp.isDisposed) return;
          vp.setVolume(volume ? 1 : 0);
          _updateTelemetryHintsForCurrentPage(
            isAudible: volume,
            hasStableFocus: false,
          );
          if (currentPage >= 0 && currentPage < shorts.length) {
            _requestExclusivePlayback(shorts[currentPage].docID);
          }
        } catch (_) {}
      }
    }
  }

  final Map<int, bool> _completionTriggered = {};

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          // Pop'tan önce tüm video seslerini durdur
          try {
            VideoStateManager.instance.exitExclusiveMode();
          } catch (_) {}
          await _pauseAllControllers();
          // Çıkarken mevcut pozisyonu geri gönder
          final idx = widget.startModel != null
              ? shorts.indexWhere((p) => p.docID == widget.startModel!.docID)
              : currentPage;
          final ctrl = idx >= 0 ? _videoControllers[idx] : null;
          final docID = widget.startModel?.docID ??
              (shorts.isNotEmpty ? shorts[currentPage].docID : null);
          final pos = (ctrl != null && ctrl.value.isInitialized)
              ? ctrl.value.position
              : Duration.zero;
          Navigator.of(context).pop({
            'docID': docID,
            'positionMs': pos.inMilliseconds,
          });
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Obx(() {
            if (shorts.isEmpty) {
              return const Center(
                child: CupertinoActivityIndicator(color: Colors.white),
              );
            }
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragStart: _handleManualVerticalDragStart,
              onVerticalDragUpdate: _handleManualVerticalDragUpdate,
              onVerticalDragEnd: _handleManualVerticalDragEnd,
              child: PageView.builder(
                controller: pageController,
                scrollDirection: Axis.vertical,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shorts.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (ctx, idx) {
                  // Sadece başlangıç sayfası ve injectedController'ın kullanılacağı ilk frame için özel durum
                  if (idx == _initialIndexForSeek &&
                      _initialIndexForSeek != null &&
                      widget.injectedController != null &&
                      widget.injectedController!.value.isInitialized &&
                      idx == currentPage) {
                    final injected = widget.injectedController!;
                    // Haritaya henüz eklenmediyse ekle ve sahipliğini işaretle
                    if (!_videoControllers.containsKey(idx)) {
                      _videoControllers[idx] = injected;
                      _externallyOwned.add(idx);
                      // Injected controller'ın ses seviyesini ayarla
                      injected.setVolume(volume ? 1 : 0);
                    }
                    final injThumb = shorts[idx].thumbnail;
                    final injectedWidget = Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildFullscreenVideoSurface(
                          injected,
                          'injected-${shorts[idx].docID}-${injected.hashCode}',
                          overrideAutoPlay: true,
                          modelAspectRatio: shorts[idx].aspectRatio.toDouble(),
                        ),
                        // Thumbnail overlay - native view ilk frame'i render edene kadar
                        AnimatedBuilder(
                          animation: injected,
                          builder: (_, __) {
                            final v = injected.value;
                            final hideThumb = v.hasRenderedFirstFrame;
                            if (hideThumb) {
                              return const SizedBox.shrink();
                            }
                            if (injThumb.isEmpty)
                              return const SizedBox.shrink();
                            if (shorts[idx].aspectRatio >= 0.8) {
                              return Align(
                                alignment: Alignment.center,
                                child: AspectRatio(
                                  aspectRatio: shorts[idx].aspectRatio > 1.2
                                      ? shorts[idx].aspectRatio.toDouble()
                                      : 1.0,
                                  child: _cachedThumb(injThumb),
                                ),
                              );
                            }
                            return SizedBox.expand(
                              child: _cachedThumb(injThumb),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: injected,
                          builder: (_, __) {
                            if (!injected.value.isInitialized) {
                              return const Center(
                                child: CupertinoActivityIndicator(
                                    color: Colors.white),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    );
                    return _buildStackForController(
                        idx, injectedWidget, injected);
                  }

                  // Normal video controller'ları için
                  final thumb = shorts[idx].thumbnail;
                  if (!_videoControllers.containsKey(idx)) {
                    _ensureController(idx);
                    // Thumbnail göster (yüklenirken)
                    final loadingThumbAr = shorts[idx].aspectRatio.toDouble();
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (thumb.isNotEmpty)
                          if (loadingThumbAr >= 0.8)
                            Center(
                              child: AspectRatio(
                                aspectRatio:
                                    loadingThumbAr > 1.2 ? loadingThumbAr : 1.0,
                                child: _cachedThumb(thumb),
                              ),
                            )
                          else
                            _cachedThumb(thumb)
                        else
                          const SizedBox.shrink(),
                        const Center(
                          child:
                              CupertinoActivityIndicator(color: Colors.white),
                        ),
                      ],
                    );
                  }

                  final vp = _videoControllers[idx]!;

                  // Sadece yakın sayfalardaki videoları render et
                  final isNear = (idx - currentPage).abs() <= 2;
                  final thumbAr = shorts[idx].aspectRatio.toDouble();
                  final videoWidget = !isNear
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            if (thumb.isNotEmpty)
                              if (thumbAr >= 0.8)
                                Center(
                                  child: AspectRatio(
                                    aspectRatio: thumbAr > 1.2 ? thumbAr : 1.0,
                                    child: _cachedThumb(thumb),
                                  ),
                                )
                              else
                                _cachedThumb(thumb),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildFullscreenVideoSurface(
                              vp,
                              'vp-${shorts[idx].docID}-${vp.hashCode}',
                              modelAspectRatio:
                                  shorts[idx].aspectRatio.toDouble(),
                            ),
                            // Thumbnail overlay - video ilk frame'i gösterene kadar
                            AnimatedBuilder(
                              animation: vp,
                              builder: (_, __) {
                                final v = vp.value;
                                final hideThumb = v.hasRenderedFirstFrame;
                                if (hideThumb) {
                                  return const SizedBox.shrink();
                                }
                                if (thumb.isEmpty)
                                  return const SizedBox.shrink();
                                if (shorts[idx].aspectRatio >= 0.8) {
                                  return Align(
                                    alignment: Alignment.center,
                                    child: AspectRatio(
                                      aspectRatio: shorts[idx].aspectRatio > 1.2
                                          ? shorts[idx].aspectRatio.toDouble()
                                          : 1.0,
                                      child: _cachedThumb(thumb),
                                    ),
                                  );
                                }
                                return SizedBox.expand(
                                  child: _cachedThumb(thumb),
                                );
                              },
                            ),
                            AnimatedBuilder(
                              animation: vp,
                              builder: (_, __) {
                                if (!vp.value.isInitialized) {
                                  return const Center(
                                    child: CupertinoActivityIndicator(
                                        color: Colors.white),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        );

                  return _buildStackForController(idx, videoWidget, vp);
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStackForController(
      int idx, Widget videoWidget, HLSVideoAdapter vp) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video widget (scroll engellememesi için GestureDetector kaldırıldı)
        videoWidget,
        // İnce progress bar
        if (showControls && idx == currentPage)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SingleShortProgressBar(adapter: vp),
          ),
        ShortsContent(
          model: shorts[idx],
          isActive: idx == currentPage,
          showOverlayControls: showControls,
          onToggleOverlay: () {
            if (!mounted) return;
            setState(() {
              showControls = !showControls;
            });
          },
          onDoubleTapLike: () async {
            if (idx < 0 || idx >= shorts.length) return;
            await PostRepository.ensure().toggleLike(shorts[idx]);
          },
          volumeOff: (volume) {
            if (!volume) {
              vp.pause();
              if (idx == currentPage) {
                _updateTelemetryHintsForCurrentPage(
                  isAudible: this.volume,
                  hasStableFocus: false,
                );
              }
              return;
            }
            if (idx == currentPage && idx < shorts.length) {
              _updateTelemetryHintsForCurrentPage(
                isAudible: this.volume,
                hasStableFocus: true,
              );
              _requestExclusivePlayback(shorts[idx].docID);
            }
          },
          videoPlayerController: vp,
        ),
        if (showControls)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppBackButton(
                        icon: CupertinoIcons.arrow_left,
                        iconColor: Colors.white,
                        surfaceColor: const Color(0x50000000),
                        onTap: () async {
                          try {
                            VideoStateManager.instance.exitExclusiveMode();
                          } catch (_) {}
                          await _pauseAllControllers();
                          final idx0 = widget.startModel != null
                              ? shorts.indexWhere(
                                  (p) => p.docID == widget.startModel!.docID)
                              : currentPage;
                          final ctrl =
                              idx0 >= 0 ? _videoControllers[idx0] : null;
                          final docID = widget.startModel?.docID ??
                              (shorts.isNotEmpty
                                  ? shorts[currentPage].docID
                                  : null);
                          final pos = (ctrl != null && ctrl.value.isInitialized)
                              ? ctrl.value.position
                              : Duration.zero;
                          Navigator.of(context).pop({
                            'docID': docID,
                            'positionMs': pos.inMilliseconds,
                          });
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildTopCircleButton(
                            icon: volume
                                ? CupertinoIcons.volume_up
                                : CupertinoIcons.volume_off,
                            onTap: () => setState(() {
                              volume = !volume;
                              final ctrl = _videoControllers[currentPage];
                              if (ctrl != null) {
                                ctrl.setVolume(volume ? 1 : 0);
                                if (_externallyOwned.contains(currentPage) &&
                                    widget.injectedController != null) {
                                  widget.injectedController!
                                      .setVolume(volume ? 1 : 0);
                                }
                              }
                              _updateTelemetryHintsForCurrentPage(
                                isAudible: volume,
                              );
                            }),
                          ),
                          if (shorts[idx].floodCount > 1)
                            IconButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                minimumSize: const Size(36, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.black.withAlpha(50),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12)),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  if (vp.value.isInitialized) {
                                    await vp.pause();
                                  }
                                } catch (_) {}
                                await Get.to(
                                    () => FloodListing(mainModel: shorts[idx]));
                                if (!mounted) return;
                                if (idx == currentPage) {
                                  try {
                                    vp.setVolume(volume ? 1 : 0);
                                    _updateTelemetryHintsForCurrentPage(
                                      isAudible: volume,
                                      hasStableFocus: false,
                                    );
                                    _requestExclusivePlayback(
                                        shorts[idx].docID);
                                  } catch (_) {}
                                }
                              },
                              icon: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [Colors.white, Colors.blue],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(Rect.fromLTWH(
                                        0, 0, bounds.width, bounds.height)),
                                blendMode: BlendMode.srcIn,
                                child: Text(
                                  "${shorts[idx].floodCount} ${'saved_posts.series_badge'.tr}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(50),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
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
