import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import '../../Models/posts_model.dart';

class DynamicShortView extends StatefulWidget {
  final PostsModel startModel;
  final List<PostsModel> startList;
  final HLSVideoAdapter playerController;

  const DynamicShortView({
    super.key,
    required this.startModel,
    required this.startList,
    required this.playerController,
  });

  @override
  DynamicShortViewState createState() => DynamicShortViewState();
}

class DynamicShortViewState extends State<DynamicShortView> {
  final PageController pageController = PageController();
  late List<HLSVideoAdapter?> controllers;
  late List<bool> isInitialized;
  int currentPage = 0;

  static const int preloadCount = 1;

  @override
  void initState() {
    super.initState();
    // Tüm controller ve isInitialized dizilerini hazırla
    controllers = List<HLSVideoAdapter?>.filled(widget.startList.length, null);
    isInitialized = List<bool>.filled(widget.startList.length, false);

    // İlk video dışarıdan hazır, ata
    controllers[0] = widget.playerController;
    _setupController(0);

    // Etrafındaki videoları preload et
    _preloadWindow(0);
  }

  // Controller'ı hazırla ve aktifse oynat
  void _setupController(int idx) {
    final controller = controllers[idx];
    if (controller == null) return;

    // HLSVideoAdapter auto-initializes when buildPlayer mounts
    isInitialized[idx] = true;
    if (currentPage == idx) _playOnly(idx);
    setState(() {});
  }

  // Sadece 7 ileri, 7 geri ve mevcut videoyu preload et
  void _preloadWindow(int center) {
    int min = (center - preloadCount).clamp(0, widget.startList.length - 1);
    int max = (center + preloadCount).clamp(0, widget.startList.length - 1);
    for (int i = min; i <= max; i++) {
      if (controllers[i] != null) continue;
      if (i == 0) continue; // 1. video zaten hazır
      final post = widget.startList[i];
      final ctrl =
          HLSVideoAdapter(url: post.playbackUrl, autoPlay: false, loop: true);
      controllers[i] = ctrl;
      _setupController(i);
    }
  }

  // Yalnızca ekrandaki video oynar, diğerleri pause
  void _playOnly(int idx) {
    for (int i = 0; i < controllers.length; i++) {
      final c = controllers[i];
      if (c == null) continue;
      if (i == idx) {
        // Pending queue sayesinde view hazır değilse komut kuyruklanır
        c.play();
      } else {
        c.pause();
        c.seekTo(Duration.zero);
      }
    }
  }

  @override
  void dispose() {
    for (int i = 1; i < controllers.length; i++) {
      controllers[i]?.dispose();
    }
    pageController.dispose();
    super.dispose();
  }

  void onPageChanged(int idx) {
    setState(() {
      currentPage = idx;
    });
    _playOnly(idx);
    _preloadWindow(idx);
  }

  void togglePlayPause(int idx) {
    final ctrl = controllers[idx];
    if (ctrl == null) return;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
    } else {
      ctrl.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Aktif controller henüz oluşturulmadıysa loading göster
    final controller = controllers[currentPage];
    if (controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CupertinoActivityIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.startList.length,
        onPageChanged: onPageChanged,
        itemBuilder: (ctx, idx) {
          final ctrl = controllers[idx];
          final isReady =
              ctrl != null && isInitialized[idx] && ctrl.value.isInitialized;

          Widget preloadLabel = Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
                decoration: BoxDecoration(
                  color: isReady ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isReady ? "PRELOADED" : "NOT PRELOADED",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );

          // Controller yoksa henüz preload edilmemiş — loading göster
          if (ctrl == null) {
            return Stack(
              children: [
                const Center(
                    child: CupertinoActivityIndicator(color: Colors.white)),
                preloadLabel,
              ],
            );
          }

          // buildPlayer() HER ZAMAN render edilmeli — native view mount olması için.
          // isReady false ise üstüne loading overlay koyuyoruz.
          return Stack(
            alignment: Alignment.center,
            children: [
              // Native video player — her zaman render et
              SizedBox.expand(
                child: ctrl.buildPlayer(),
              ),
              // Henüz hazır değilse loading overlay
              if (!isReady)
                const Center(
                    child: CupertinoActivityIndicator(color: Colors.white)),
              preloadLabel,
              if (currentPage == idx)
                Positioned(
                  bottom: 48,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => togglePlayPause(idx),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          ctrl.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
