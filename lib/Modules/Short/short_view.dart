import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/debug_overlay.dart';
import 'package:turqappv2/Core/Widgets/Ads/ad_placement_hooks.dart';
import 'package:turqappv2/Services/user_analytics_service.dart';
import 'package:turqappv2/Core/Services/video_telemetry_service.dart';
import 'short_controller.dart';
import 'short_content.dart';
import '../../Models/posts_model.dart';

class MomentumPageScrollPhysics extends PageScrollPhysics {
  const MomentumPageScrollPhysics({
    this.maxPagesPerFling = 4,
    this.baseMinFlingVelocity = 600.0,
    super.parent,
  });

  final int maxPagesPerFling;
  final double baseMinFlingVelocity;

  @override
  MomentumPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return MomentumPageScrollPhysics(
      maxPagesPerFling: maxPagesPerFling,
      baseMinFlingVelocity: baseMinFlingVelocity,
      parent: buildParent(ancestor),
    );
  }

  @override
  double get minFlingVelocity => baseMinFlingVelocity;

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent) ||
        position.viewportDimension <= 0) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    if (velocity.abs() < tolerance.velocity) {
      return super.createBallisticSimulation(position, velocity);
    }

    final page = position.pixels / position.viewportDimension;
    final minPage = position.minScrollExtent / position.viewportDimension;
    final maxPage = position.maxScrollExtent / position.viewportDimension;

    int pagesToAdvance = 1;
    if (velocity.abs() > baseMinFlingVelocity * 1.8) pagesToAdvance = 2;
    if (velocity.abs() > baseMinFlingVelocity * 2.8) {
      pagesToAdvance = maxPagesPerFling;
    }

    final targetPage = velocity > 0
        ? (page.ceilToDouble() + (pagesToAdvance - 1))
        : (page.floorToDouble() - (pagesToAdvance - 1));
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
  bool _didInitialAttach = false;
  bool _isTransitioning = false;
  bool _isRefreshing = false;
  List<PostsModel> _cachedShorts = [];

  // Scroll debounce — hızlı kaydırmada gereksiz adapter oluşturmayı engeller
  Timer? _scrollDebounce;
  Timer? _playDebounce;
  Timer? _tierDebounce;
  static const Duration _playResumeDelay = Duration(milliseconds: 50);
  static const Duration _playResumeDelayAndroid = Duration.zero;
  static const Duration _scrollDebounceAndroid = Duration(milliseconds: 24);
  static const Duration _tierDebounceDelay = Duration(milliseconds: 70);
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
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await adapter.stopPlayback();
      return;
    }
    await adapter.pause();
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

    currentPage = page;
    isManuallyPaused = false;
    _isTransitioning = false;
    _telemetryFirstFrame = false;
    _telemetryAdapter = null;

    // Yeni video için progress tracking'i sıfırla
    // Sıfırlanmazsa eski videonun progress değeri delta hesabını bozar
    _lastPersistedProgress = 0.0;
    _lastProgressPersistAt = null;

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
    _tierDebounce = Timer(_tierDebounceDelay, () {
      if (!mounted || page != currentPage) return;
      unawaited(controller.updateCacheTiers(page));
    });
  }

  Future<void> _startAutoPlayCurrentVideo() async {
    if (controller.shorts.isEmpty) return;

    isManuallyPaused = false;

    // Cache tier'larını güncelle (ilk 5 preload dahil)
    await controller.updateCacheTiers(currentPage);

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
        _telemetryFirstFrame = false;
        _telemetryAdapter = vc;
        vc.addListener(_telemetryListener);
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

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _playDebounce?.cancel();
    _tierDebounce?.cancel();
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

          final content = RefreshIndicator(
            onRefresh: _handleRefresh,
            backgroundColor: Colors.transparent,
            color: Colors.white,
            strokeWidth: 3.0,
            displacement: 50.0,
            child: PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              physics: MomentumPageScrollPhysics(
                maxPagesPerFling:
                    defaultTargetPlatform == TargetPlatform.android ? 2 : 4,
                baseMinFlingVelocity:
                    defaultTargetPlatform == TargetPlatform.android
                        ? 500.0
                        : 600.0,
                parent: const AlwaysScrollableScrollPhysics(),
              ),
              itemCount: list.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, idx) {
                final vp = controller.cache[idx];

                if (vp == null) {
                  return const Center(
                    child: CupertinoActivityIndicator(color: Colors.white),
                  );
                }

                // PURE BUILD — side effect yok, sadece widget döndür
                final modelAr = list[idx].aspectRatio > 0
                    ? list[idx].aspectRatio.toDouble()
                    : (9 / 16);

                // 3-tier: portrait (<0.8) → fill, square (0.8-1.2) → kare frame, landscape (>1.2) → yatay frame
                Widget videoWidget;
                if (modelAr > 1.2) {
                  // Yatay dikdörtgen
                  videoWidget = Center(
                    child: AspectRatio(
                      aspectRatio: modelAr,
                      child: vp.buildPlayer(useAspectRatio: false),
                    ),
                  );
                } else if (modelAr >= 0.8) {
                  // Kare frame
                  videoWidget = Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: vp.buildPlayer(useAspectRatio: false),
                    ),
                  );
                } else {
                  // Dikey — ekranı doldur
                  videoWidget = SizedBox.expand(
                    child: vp.buildPlayer(),
                  );
                }

                return RepaintBoundary(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Video layer
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: () {
                          // Çift dokunma: ses aç/kapa
                          setState(() => volume = !volume);
                          vp.setVolume(volume ? 1 : 0);
                        },
                        child: videoWidget,
                      ),
                      ShortsContent(
                        model: list[idx],
                        volumeOff: (v) {
                          if (v) {
                            vp.play();
                            isManuallyPaused = false;
                          } else {
                            vp.pause();
                            isManuallyPaused = true;
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
                      if (idx == currentPage)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _ShortProgressBar(adapter: vp),
                        ),
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
