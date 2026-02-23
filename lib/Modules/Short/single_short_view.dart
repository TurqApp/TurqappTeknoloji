import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../main.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import '../../Models/posts_model.dart';
import '../../Core/Services/playback_handle.dart';
import '../../Core/Services/video_state_manager.dart';
import '../../Core/Services/SegmentCache/cache_manager.dart';
import 'short_content.dart';
import '../Agenda/FloodListing/flood_listing.dart';

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

  final PageController pageController = PageController();
  int currentPage = 0;
  bool volume = true;
  bool showControls = true;

  /// index → VideoPlayerController
  final Map<int, HLSVideoAdapter> _videoControllers = {};
  int? _initialIndexForSeek; // initialPosition seek uygulanacak index
  final Set<int> _externallyOwned = <int>{}; // dispose etmeyeceğimiz indexler

  Future<void> _pauseAllControllers() async {
    // Aktif ve bufferlanan tüm video controller'larını güvenli şekilde durdur
    for (final vp in _videoControllers.values) {
      try {
        if (vp.value.isInitialized && vp.value.isPlaying) {
          await vp.pause();
        }
      } catch (_) {}
    }
    // Enjekte edilmiş bir controller varsa, onun da sesi kesilsin
    final injected = widget.injectedController;
    if (injected != null) {
      try {
        if (injected.value.isInitialized && injected.value.isPlaying) {
          await injected.pause();
        }
      } catch (_) {}
    }
  }

  Widget _buildFullscreenVideoSurface(HLSVideoAdapter adapter, String keyId) {
    final ar =
        adapter.value.aspectRatio > 0 ? adapter.value.aspectRatio : (9 / 16);

    return LayoutBuilder(
      builder: (context, constraints) {
        final frameHeight = constraints.maxHeight > 0
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;
        final targetWidth = frameHeight * ar;

        return ClipRect(
          child: Center(
            child: SizedBox(
              width: targetWidth,
              height: frameHeight,
              child: adapter.buildPlayer(
                key: ValueKey(keyId),
                useAspectRatio: false,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

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

  void _configureInitialForList(List<PostsModel> list) {
    // startModel listede nerede ise oraya ayarla
    int initial = 0;
    if (widget.startModel != null) {
      final idx = list.indexWhere((p) => p.docID == widget.startModel!.docID);
      if (idx != -1) initial = idx;
    } else if (list.isNotEmpty) {
      initial = 0;
    }
    currentPage = initial;
    _initialIndexForSeek = initial;
    if (widget.injectedController != null &&
        widget.injectedController!.value.isInitialized) {
      _videoControllers[initial] = widget.injectedController!;
      _externallyOwned.add(initial);
      final ctrl = widget.injectedController!;

      print('[SingleShortView] 📺 Configuring injected controller');
      print(
          '[SingleShortView] Initial position received: ${widget.initialPosition}');
      print('[SingleShortView] Controller duration: ${ctrl.value.duration}');
      print(
          '[SingleShortView] Controller current position: ${ctrl.value.position}');
      print('[SingleShortView] Controller isPlaying: ${ctrl.value.isPlaying}');

      // Pozisyonu set et ve oynat - PostFrameCallback ile
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          print('[SingleShortView] ❌ Not mounted, aborting');
          return;
        }

        try {
          // Ayarları uygula
          ctrl.setVolume(volume ? 1 : 0);
          ctrl.setLooping(false); // Otomatik geçiş için loop kapalı

          // initialPosition varsa o pozisyona git
          if (widget.initialPosition != null &&
              widget.initialPosition != Duration.zero) {
            final targetPos = widget.initialPosition!;
            final total = ctrl.value.duration;
            final safePos = targetPos > total
                ? total
                : (targetPos.isNegative ? Duration.zero : targetPos);

            print('[SingleShortView] 🎯 Seeking to: $safePos');
            await ctrl.seekTo(safePos);
            print(
                '[SingleShortView] ✅ Seek completed. New position: ${ctrl.value.position}');
          } else {
            print(
                '[SingleShortView] ⏭️ No initial position, starting from current');
          }

          // Oynat - birkaç kez dene
          if (mounted) {
            print('[SingleShortView] ▶️ Calling play()...');
            await ctrl.play();

            // Play sonrası kısa bekle ve kontrol et
            await Future.delayed(const Duration(milliseconds: 100));

            print(
                '[SingleShortView] ✅ Play completed. isPlaying: ${ctrl.value.isPlaying}');

            // Hala oynatılmıyorsa tekrar dene
            if (!ctrl.value.isPlaying) {
              print('[SingleShortView] ⚠️ Still not playing, retrying...');
              await ctrl.play();
              await Future.delayed(const Duration(milliseconds: 50));
              print(
                  '[SingleShortView] 🔄 Retry result. isPlaying: ${ctrl.value.isPlaying}');
            }

            if (mounted) {
              setState(() {});
            }
          }
        } catch (e) {
          print('[SingleShortView] ❌ Error during setup: $e');
          // Hata olursa yine de oynatmayı dene
          try {
            if (mounted) {
              print('[SingleShortView] 🔄 Emergency retry: calling play()...');
              await ctrl.play();
              if (mounted) setState(() {});
            }
          } catch (e2) {
            print('[SingleShortView] ❌ Emergency retry also failed: $e2');
          }
        }
      });

      setState(() {});
    } else {
      // Injected controller hazır değilse hızlıca lokal controller oluştur.
      _initialIndexForSeek = null;
      _ensureController(initial);
      print(
          '[SingleShortView] Injected controller hazır değil, local controller kullanılıyor.');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.jumpToPage(initial);
      }
    });
    if (list.isNotEmpty) _preloadRange(initial);
  }

  void _handleShortsChange(List<PostsModel> list) {
    // Mevcut kontrolleri temizle: enjekte edilen hariç
    final injected = widget.injectedController;
    final entries = _videoControllers.entries.toList();
    for (final e in entries) {
      final c = e.value;
      if (injected != null && identical(c, injected)) {
        // Bu controller dışarıya ait; dispose etmiyoruz
        continue;
      }
      try {
        c.pause();
      } catch (_) {}
      try {
        c.dispose();
      } catch (_) {}
      _videoControllers.remove(e.key);
    }
    _externallyOwned.clear();

    // Listeyi yeni initial ile yapılandır
    _configureInitialForList(list);
  }

  Future<void> _fetchAndShuffle() async {
    List<PostsModel> items = [];

    try {
      final snap = await FirebaseFirestore.instance
          .collection('Posts')
          .where('hlsStatus', isEqualTo: 'ready')
          .limit(1000)
          .get();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      items = snap.docs
          .map(PostsModel.fromFirestore)
          .where((p) => (p.timeStamp) <= nowMs)
          .toList()
        ..shuffle();
    } catch (e) {
      print("fetch error: $e");
    }

    final merged = <PostsModel>[];

    if (widget.startList != null && widget.startList!.isNotEmpty) {
      // Eğer startList varsa ve içinde startModel yoksa önce startModel
      if (widget.startModel != null &&
          widget.startList!.every((p) => p.docID != widget.startModel!.docID)) {
        merged.add(widget.startModel!);
      }
      merged.addAll(widget.startList!);
    } else if (widget.startModel != null) {
      // Sadece tek model varsa
      merged.add(widget.startModel!);
    }

    // Son olarak Firestore’dan gelenleri ekle
    merged.addAll(items);

    shorts.assignAll(merged);
    _configureInitialForList(merged);
  }

  void _onPageChanged(int page) {
    if (page == currentPage) return;

    // 1) Önceki videoyu durdur
    final prev = _videoControllers[currentPage];
    if (prev != null) {
      try {
        prev.pause();
      } catch (_) {}
    }

    // 2) Yeni sayfayı ata
    currentPage = page;

    // Yarış koşullarını azalt: yeni sayfa dışında tüm controller'ları durdur.
    for (final entry in _videoControllers.entries) {
      if (entry.key == currentPage) continue;
      try {
        entry.value.pause();
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
        injected.pause();
      } catch (_) {}
    }

    if (vp != null) {
      try {
        vp.setVolume(volume ? 1 : 0);
      } catch (_) {}
      try {
        vp.play();
      } catch (_) {}

      // Cache state machine: playing olarak işaretle
      if (currentPage < shorts.length) {
        try {
          Get.find<SegmentCacheManager>()
              .markPlaying(shorts[currentPage].docID);
        } catch (_) {}
      }
    }
    // 5) ±5 aralığı preload & dışındakileri dispose et
    _preloadRange(currentPage);
    _disposeOutsideRange(currentPage);
    setState(() {});
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
    _clearAllControllers();
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
            HLSPlaybackHandle(ctrl.hlsController),
          );

          print(
              '[SingleShortView] 🔙 Saved position: ${ctrl.value.position} for ${currentModel.docID}');
        }
      }
    } catch (e) {
      print('[SingleShortView] Error during didPop: $e');
    }

    // Tüm videoları durdur
    _pauseAllControllers();
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
          vp.setVolume(volume ? 1 : 0);
          vp.play();
        } catch (_) {}
      }
    }
  }

  void _clearAllControllers() {
    // Harici sahip olunan controller'lara dokunma (pause/dispose yok)
    final keys = _videoControllers.keys.toList();
    for (final idx in keys) {
      final c = _videoControllers[idx]!;
      if (_externallyOwned.contains(idx)) {
        // bırak: görüntüleyen sayfa kullanmaya devam edecek
        continue;
      }
      c.pause();
      c.dispose();
      _videoControllers.remove(idx);
    }
    // externals set'i koru; injected mapping kalır
  }

  void _preloadRange(int center) {
    final len = shorts.length;
    final start = (center - 1).clamp(0, len - 1);
    final end = (center + 1).clamp(0, len - 1);
    for (var i = start; i <= end; i++) {
      _ensureController(i);
    }
  }

  void _ensureController(int index) {
    if (index < 0 || index >= shorts.length) return;
    if (_videoControllers.containsKey(index)) return;

    // injectedController sadece başlangıçta ve sadece ilk index için kullanılır
    if (_initialIndexForSeek != null &&
        index == _initialIndexForSeek &&
        widget.injectedController != null &&
        widget.injectedController!.value.isInitialized &&
        !_videoControllers.containsKey(index)) {
      // Injected controller için listener ekle
      _addVideoCompletionListener(widget.injectedController!, index);
      return;
    }

    final url = shorts[index].playbackUrl;
    if (url.isEmpty) return;

    final ctrl = HLSVideoAdapter(url: url, autoPlay: false, loop: false);
    _videoControllers[index] = ctrl;

    ctrl.setLooping(false); // Loop'u kapat, manuel geçiş yapacağız

    // Video bittiğinde sonraki videoya geç
    _addVideoCompletionListener(ctrl, index);

    // Eğer bu index aktif sayfa ise ses ayarı ve oynatma
    if (index == currentPage) {
      ctrl.setVolume(volume ? 1 : 0);
      // Başlangıç pozisyonu sadece ilk video için uygulanır
      if (_initialIndexForSeek != null &&
          index == _initialIndexForSeek &&
          widget.initialPosition != null) {
        final pos = widget.initialPosition!;
        final total = ctrl.value.duration;
        final safePos =
            pos > total ? total : (pos.isNegative ? Duration.zero : pos);
        ctrl.seekTo(safePos).then((_) {
          if (mounted && index == currentPage) ctrl.play();
        });
      } else {
        ctrl.play();
      }
    }
    if (mounted) setState(() {});
  }

  final Map<int, bool> _completionTriggered = {};

  void _addVideoCompletionListener(HLSVideoAdapter ctrl, int index) {
    ctrl.addListener(() {
      if (!mounted) return;
      if (index != currentPage) return; // Sadece aktif video için kontrol et

      final value = ctrl.value;
      if (!value.isInitialized) return;

      // Trigger edilmiş mi kontrol et
      if (_completionTriggered[index] == true) return;

      final position = value.position;
      final duration = value.duration;

      // Video sona yaklaştı mı? (son 300ms)
      if (duration.inMilliseconds > 0 &&
          position >= duration - const Duration(milliseconds: 300) &&
          position.inMilliseconds > 0) {
        _completionTriggered[index] = true;

        print('[SingleShortView] 🎬 Video $index tamamlandı');
        print(
            '[SingleShortView] ⏱️  ${position.inSeconds}/${duration.inSeconds}s');

        // Sonraki videoya geç
        final nextIndex = currentPage + 1;
        if (nextIndex < shorts.length) {
          print(
              '[SingleShortView] ⏭️  Video $nextIndex\'e geçiliyor (nextPage ile)');
          if (pageController.hasClients) {
            // nextPage kullan (Short ekranı gibi)
            pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        } else {
          print('[SingleShortView] 📝 Son video, başa sarılıyor');
          // Son videoysa başa sar
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              ctrl.seekTo(Duration.zero);
              ctrl.play();
              _completionTriggered[index] = false;
            }
          });
        }
      }
    });
  }

  void _disposeOutsideRange(int center) {
    final len = shorts.length;
    final start = (center - 2).clamp(0, len - 1);
    final end = (center + 2).clamp(0, len - 1);
    final keys = _videoControllers.keys.toList();
    for (var idx in keys) {
      if (idx < start || idx > end) {
        if (!_externallyOwned.contains(idx)) {
          _videoControllers[idx]?.dispose();
          _videoControllers.remove(idx);
        }
      }
    }
  }

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
            return PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              physics: const MomentumPageScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
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
                  final injectedWidget = Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildFullscreenVideoSurface(
                        injected,
                        'injected-${shorts[idx].docID}-${injected.hashCode}',
                      ),
                      if (!injected.value.isInitialized)
                        const Center(
                          child:
                              CupertinoActivityIndicator(color: Colors.white),
                        ),
                    ],
                  );
                  return _buildStackForController(
                      idx, injectedWidget, injected);
                }

                // Normal video controller'ları için
                if (!_videoControllers.containsKey(idx)) {
                  _ensureController(idx);
                  return const Center(
                    child: CupertinoActivityIndicator(color: Colors.white),
                  );
                }

                final vp = _videoControllers[idx]!;

                // Sadece yakın sayfalardaki videoları render et
                final isNear = (idx - currentPage).abs() <= 2;
                final videoWidget = !isNear
                    ? const Center(
                        child: CupertinoActivityIndicator(color: Colors.white),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildFullscreenVideoSurface(
                            vp,
                            'vp-${shorts[idx].docID}-${vp.hashCode}',
                          ),
                          if (!vp.value.isInitialized)
                            const Center(
                              child: CupertinoActivityIndicator(
                                  color: Colors.white),
                            ),
                        ],
                      );

                return _buildStackForController(idx, videoWidget, vp);
              },
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
        // Tap kontrolü için şeffaf overlay (translucent = scroll'a izin verir)
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) => vp.pause(),
          onTapUp: (_) {
            if (idx == currentPage) vp.play();
          },
          onTapCancel: () {
            if (idx == currentPage) vp.play();
          },
          onTap: () async {
            final model = shorts[idx];
            if (model.floodCount > 1 && model.flood == false) {
              try {
                if (vp.value.isInitialized) {
                  await vp.pause();
                }
              } catch (_) {}
              await Get.to(() => FloodListing(mainModel: model));
              if (!mounted) return;
              if (idx == currentPage) {
                try {
                  vp.setVolume(volume ? 1 : 0);
                  vp.play();
                } catch (_) {}
              }
            }
          },
          child: Container(color: Colors.transparent),
        ),
        if (showControls)
          ShortsContent(
            model: shorts[idx],
            volumeOff: (volume) {
              if (volume) {
                vp.play();
              } else {
                vp.pause();
              }
            },
            videoPlayerController: vp,
          ),
        SafeArea(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.arrow_left,
                        color: Colors.white),
                    onPressed: () async {
                      // Pop'tan önce tüm video seslerini durdur
                      await _pauseAllControllers();
                      // Geri dönerken pozisyonu ilet
                      final idx0 = widget.startModel != null
                          ? shorts.indexWhere(
                              (p) => p.docID == widget.startModel!.docID)
                          : currentPage;
                      final ctrl = idx0 >= 0 ? _videoControllers[idx0] : null;
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
                      IconButton(
                        icon: Icon(volume
                            ? CupertinoIcons.volume_up
                            : CupertinoIcons.volume_off),
                        color: Colors.white,
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                            width: 36, height: 36),
                        onPressed: () => setState(() {
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
                                vp.play();
                              } catch (_) {}
                            }
                          },
                          icon: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Colors.blue],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(Rect.fromLTWH(
                                0, 0, bounds.width, bounds.height)),
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              "${shorts[idx].floodCount} FLOOD",
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
      ],
    );
  }
}
