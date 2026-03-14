import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/short_repository.dart';
import '../../main.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import '../../Models/posts_model.dart';
import '../../Core/Services/global_video_adapter_pool.dart';
import '../../Core/Services/playback_handle.dart';
import '../../Core/Services/video_state_manager.dart';
import '../../Core/Services/SegmentCache/cache_manager.dart';
import 'short_content.dart';
import '../Agenda/FloodListing/flood_listing.dart';

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

  final PageController pageController = PageController();
  int currentPage = 0;
  bool volume = true;
  bool showControls = true;
  DateTime _pageActivatedAt = DateTime.now();
  bool _manualSnapInProgress = false;
  double _manualGestureDragDy = 0.0;
  static const double _manualGestureTriggerDistance = 18.0;
  static const double _manualGestureTriggerVelocity = 80.0;

  /// index → VideoPlayerController
  final Map<int, HLSVideoAdapter> _videoControllers = {};
  final Map<int, VoidCallback> _completionListeners = <int, VoidCallback>{};
  int? _initialIndexForSeek; // initialPosition seek uygulanacak index
  final Set<int> _externallyOwned = <int>{}; // dispose etmeyeceğimiz indexler

  Future<void> _releasePlayback(HLSVideoAdapter adapter) async {
    if (adapter.isDisposed) return;
    await adapter.pause();
  }

  void _detachCompletionListener(int index, HLSVideoAdapter adapter) {
    final listener = _completionListeners.remove(index);
    if (listener != null) {
      adapter.removeListener(listener);
    }
  }

  Future<void> _releaseControllerAt(
    int index, {
    bool keepWarm = true,
  }) async {
    final adapter = _videoControllers[index];
    if (adapter == null) return;
    _detachCompletionListener(index, adapter);

    final docId =
        (index >= 0 && index < shorts.length) ? shorts[index].docID : null;
    if (docId != null) {
      try {
        videoStateManager.unregisterVideoController(docId);
      } catch (_) {}
    }

    _videoControllers.remove(index);
    if (adapter.isDisposed) return;
    await _videoPool.release(adapter, keepWarm: keepWarm);
  }

  Widget _cachedThumb(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Future<void> _ensureInjectedInitialPlayback(
      HLSVideoAdapter ctrl, String docId) async {
    try {
      if (ctrl.isDisposed) return;
      ctrl.setLooping(false);
      ctrl.setVolume(volume ? 1 : 0);

      final targetPos = widget.initialPosition;
      if (targetPos != null) {
        Duration safePos = targetPos.isNegative ? Duration.zero : targetPos;
        final total = ctrl.value.duration;
        if (total > Duration.zero) {
          final maxSeek = total - const Duration(milliseconds: 400);
          if (maxSeek > Duration.zero && safePos > maxSeek) {
            safePos = maxSeek;
          }
        }
        await ctrl.seekTo(safePos);
      }

      // View attach/render yarışı için garantili play denemeleri
      for (var i = 0; i < 3; i++) {
        if (!mounted || ctrl.isDisposed) return;
        await ctrl.play();
        try {
          VideoStateManager.instance.playOnlyThis(docId);
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 120));
        if (ctrl.value.isPlaying) break;
      }
    } catch (_) {}
  }

  Future<void> _pauseAllControllers() async {
    // Aktif ve bufferlanan tüm video controller'larını güvenli şekilde durdur
    for (final vp in _videoControllers.values) {
      try {
        if (vp.isDisposed) continue;
        if (vp.value.isInitialized) {
          await _releasePlayback(vp);
        }
      } catch (_) {}
    }
    // Enjekte edilmiş bir controller varsa, onun da sesi kesilsin
    final injected = widget.injectedController;
    if (injected != null) {
      try {
        if (injected.isDisposed) {
          // no-op
        } else if (injected.value.isInitialized) {
          await _releasePlayback(injected);
        }
      } catch (_) {}
    }
    try {
      VideoStateManager.instance.pauseAllVideos(force: true);
    } catch (_) {}
    try {
      VideoStateManager.instance.exitExclusiveMode();
    } catch (_) {}
  }

  void _primePlaybackForIndex(int index) {
    if (index < 0 || index >= shorts.length) return;
    final ctrl = _videoControllers[index];
    if (ctrl == null || ctrl.isDisposed) return;
    try {
      ctrl.setVolume(volume ? 1 : 0);
    } catch (_) {}
    unawaited(ctrl.play());
    try {
      VideoStateManager.instance.playOnlyThis(shorts[index].docID);
    } catch (_) {}
  }

  /// Video frame tipi:
  /// AR < 0.8  → Dikey: tam ekran doldur (mevcut davranış)
  /// 0.8 ≤ AR ≤ 1.2 → Kare: ekran genişliğinde kare frame
  /// AR > 1.2 → Yatay: ekran genişliğinde yatay dikdörtgen frame
  /// Short ekranıyla aynı 3-tier layout:
  /// portrait (<0.8) → ekranı doldur, square (0.8-1.2) → kare frame, landscape (>1.2) → yatay frame
  Widget _buildFullscreenVideoSurface(
    HLSVideoAdapter adapter,
    String keyId, {
    bool? overrideAutoPlay,
    double? modelAspectRatio,
  }) {
    // Model aspect ratio güvenilir kaynak — native player default 16/9 döner
    final ar = (modelAspectRatio != null && modelAspectRatio > 0)
        ? modelAspectRatio
        : (9 / 16);

    final player = adapter.buildPlayer(
      key: ValueKey(keyId),
      useAspectRatio: false,
      overrideAutoPlay: overrideAutoPlay,
    );

    if (ar > 1.2) {
      // Yatay dikdörtgen
      return Center(
        child: AspectRatio(
          aspectRatio: ar,
          child: player,
        ),
      );
    } else if (ar >= 0.8) {
      // Kare frame
      return Center(
        child: AspectRatio(
          aspectRatio: 1.0,
          child: player,
        ),
      );
    } else {
      // Dikey — ekranı doldur
      return SizedBox.expand(child: player);
    }
  }

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
    _pageActivatedAt = DateTime.now();
    _initialIndexForSeek = initial;
    if (widget.injectedController != null &&
        widget.injectedController!.value.isInitialized) {
      _videoControllers[initial] = widget.injectedController!;
      _externallyOwned.add(initial);
      videoStateManager.registerPlaybackHandle(
        list[initial].docID,
        HLSAdapterPlaybackHandle(widget.injectedController!),
      );
      final ctrl = widget.injectedController!;

      ctrl.setLooping(false);
      ctrl.setVolume(volume ? 1 : 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || ctrl.isDisposed || initial >= list.length) return;
        _ensureInjectedInitialPlayback(ctrl, list[initial].docID);
      });

      setState(() {});
    } else {
      // Injected controller hazır değilse hızlıca lokal controller oluştur.
      _initialIndexForSeek = null;
      _ensureController(initial);
    }
    if (list.isNotEmpty && initial >= 0 && initial < list.length) {
      try {
        VideoStateManager.instance.enterExclusiveMode(list[initial].docID);
      } catch (_) {}
      _primePlaybackForIndex(initial);
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
      unawaited(_releaseControllerAt(e.key));
    }
    _externallyOwned.clear();

    // Listeyi yeni initial ile yapılandır
    _configureInitialForList(list);
  }

  Future<void> _fetchAndShuffle() async {
    List<PostsModel> items = [];

    try {
      items = await ShortRepository.ensure().fetchRandomReadyPosts(limit: 1000)
        ..shuffle();
    } catch (_) {}

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
        _releasePlayback(prev);
      } catch (_) {}
    }

    // 2) Yeni sayfayı ata
    currentPage = page;
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
    _pauseAllControllers();
    try {
      VideoStateManager.instance.exitExclusiveMode();
    } catch (_) {}
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
          if (currentPage >= 0 && currentPage < shorts.length) {
            VideoStateManager.instance.playOnlyThis(shorts[currentPage].docID);
          }
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
      if (c.isDisposed) {
        _detachCompletionListener(idx, c);
        _videoControllers.remove(idx);
        continue;
      }
      unawaited(_releaseControllerAt(idx));
    }
    // externals set'i koru; injected mapping kalır
  }

  // +5/-5 kuralı: önündeki 5 videoyu preload et
  void _preloadRange(int center) {
    final len = shorts.length;
    final start = (center - 1).clamp(0, len - 1);
    final end = (center + 5).clamp(0, len - 1);
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
      if (index >= 0 && index < shorts.length) {
        try {
          videoStateManager.registerPlaybackHandle(
            shorts[index].docID,
            HLSAdapterPlaybackHandle(widget.injectedController!),
          );
        } catch (_) {}
      }
      // Injected controller için listener ekle
      _addVideoCompletionListener(widget.injectedController!, index);
      return;
    }

    final url = shorts[index].playbackUrl;
    if (url.isEmpty) return;

    final ctrl = _videoPool.acquire(
      cacheKey: shorts[index].docID,
      url: url,
      autoPlay: false,
      loop: false,
    );
    _videoControllers[index] = ctrl;
    try {
      videoStateManager.registerPlaybackHandle(
        shorts[index].docID,
        HLSAdapterPlaybackHandle(ctrl),
      );
    } catch (_) {}

    ctrl.setLooping(false); // Loop'u kapat, manuel geçiş yapacağız

    // Video bittiğinde sonraki videoya geç
    _addVideoCompletionListener(ctrl, index);

    // Eğer bu index aktif sayfa ise ses ayarı ve oynatma
    if (index == currentPage) {
      if (ctrl.isDisposed) return;
      // Başlangıç pozisyonu sadece ilk video için uygulanır
      if (_initialIndexForSeek != null &&
          index == _initialIndexForSeek &&
          widget.initialPosition != null &&
          widget.initialPosition! > Duration.zero) {
        // Controller henüz initialize olmadığı için duration 0 olabilir.
        // Pozisyonu doğrudan kuyruğa al, adapter view ready olunca uygular.
        final pos = widget.initialPosition!;
        ctrl.seekTo(pos);
      }
      _primePlaybackForIndex(index);
    }
    if (mounted) setState(() {});
  }

  final Map<int, bool> _completionTriggered = {};

  void _addVideoCompletionListener(HLSVideoAdapter ctrl, int index) {
    _detachCompletionListener(index, ctrl);
    void listener() {
      if (!mounted) return;
      if (index != currentPage) return; // Sadece aktif video için kontrol et

      final value = ctrl.value;
      if (!value.isInitialized) return;

      // Trigger edilmiş mi kontrol et
      if (_completionTriggered[index] == true) return;

      final position = value.position;
      final duration = value.duration;

      // Video sona yaklaştı mı? (son 300ms)
      final justActivated =
          DateTime.now().difference(_pageActivatedAt).inMilliseconds < 1200;
      if (justActivated) return;
      if (duration.inMilliseconds > 0 &&
          position >= duration - const Duration(milliseconds: 300) &&
          position.inMilliseconds > 0) {
        _completionTriggered[index] = true;

        // Sonraki videoya geç
        final nextIndex = currentPage + 1;
        if (nextIndex < shorts.length) {
          if (pageController.hasClients) {
            // nextPage kullan (Short ekranı gibi)
            pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        } else {
          // Son videoysa başa sar
          Future.delayed(const Duration(milliseconds: 100), () {
            final sameController = _videoControllers[index] == ctrl;
            if (mounted && sameController && !ctrl.isDisposed) {
              ctrl.seekTo(Duration.zero);
              if (index >= 0 && index < shorts.length) {
                VideoStateManager.instance.playOnlyThis(shorts[index].docID);
              }
              _completionTriggered[index] = false;
            }
          });
        }
      }
    }

    _completionListeners[index] = listener;
    ctrl.addListener(listener);
  }

  // +5/-5 kuralı: ±7 dışındakileri temizle (5+2 marj)
  void _disposeOutsideRange(int center) {
    final len = shorts.length;
    final start = (center - 10).clamp(0, len - 1);
    final end = (center + 10).clamp(0, len - 1);
    final keys = _videoControllers.keys.toList();
    for (var idx in keys) {
      if (idx < start || idx > end) {
        if (!_externallyOwned.contains(idx)) {
          unawaited(_releaseControllerAt(idx));
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
        // Tap kontrolü için şeffaf overlay (translucent = scroll'a izin verir)
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onDoubleTap: () {
            // Çift dokunma: ses aç/kapa
            setState(() {
              volume = !volume;
              final ctrl = _videoControllers[currentPage];
              if (ctrl != null) {
                ctrl.setVolume(volume ? 1 : 0);
              }
            });
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
                  VideoStateManager.instance.playOnlyThis(shorts[idx].docID);
                } catch (_) {}
              }
            }
          },
          child: Container(color: Colors.transparent),
        ),
        // İnce progress bar
        if (idx == currentPage)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SingleShortProgressBar(adapter: vp),
          ),
        if (showControls)
          ShortsContent(
            model: shorts[idx],
            volumeOff: (volume) {
              if (!volume) {
                vp.pause();
                return;
              }
              if (idx == currentPage && idx < shorts.length) {
                VideoStateManager.instance.playOnlyThis(shorts[idx].docID);
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
                      try {
                        VideoStateManager.instance.exitExclusiveMode();
                      } catch (_) {}
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
                                VideoStateManager.instance
                                    .playOnlyThis(shorts[idx].docID);
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

/// İnce video progress bar
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
