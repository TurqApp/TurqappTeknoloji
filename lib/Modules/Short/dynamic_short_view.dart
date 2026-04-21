import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Widgets/cache_first_network_image.dart';
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
    widget.playerController.updateWarmPoolPausePreference(
      defaultTargetPlatform == TargetPlatform.android,
    );
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
      ctrl.updateWarmPoolPausePreference(
        defaultTargetPlatform == TargetPlatform.android,
      );
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

  Widget _buildThumb(PostsModel post) {
    final thumb = post.thumbnail.trim();
    final fallbackImage = post.img.isNotEmpty ? post.img.first.trim() : '';
    final candidateUrls = <String>[
      if (thumb.isNotEmpty) thumb,
      if (fallbackImage.isNotEmpty) fallbackImage,
      ...CdnUrlBuilder.buildThumbnailUrlCandidates(post.docID.trim()),
    ];
    final primaryUrl = candidateUrls.isEmpty ? '' : candidateUrls.first.trim();
    if (primaryUrl.isEmpty) {
      return const ColoredBox(color: Colors.black);
    }
    final modelAr = post.aspectRatio > 0 ? post.aspectRatio.toDouble() : 9 / 16;
    final image = CacheFirstNetworkImage(
      imageUrl: primaryUrl,
      candidateUrls: candidateUrls.skip(1).toList(growable: false),
      cacheManager: TurqImageCacheManager.instance,
      fit: BoxFit.cover,
      fallback: const ColoredBox(color: Colors.black),
    );
    if (modelAr > 1.2) {
      return Center(
        child: AspectRatio(
          aspectRatio: modelAr,
          child: image,
        ),
      );
    }
    return SizedBox.expand(child: image);
  }

  @override
  Widget build(BuildContext context) {
    // Aktif controller henüz oluşturulmadıysa loading göster
    final controller = controllers[currentPage];
    if (controller == null) {
      final hasThumb =
          widget.startList[currentPage].thumbnail.trim().isNotEmpty;
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildThumb(widget.startList[currentPage]),
            if (!hasThumb)
              const Center(
                child: CupertinoActivityIndicator(color: Colors.white),
              ),
          ],
        ),
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
            final hasThumb = widget.startList[idx].thumbnail.trim().isNotEmpty;
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildThumb(widget.startList[idx]),
                if (!hasThumb)
                  const Center(
                    child: CupertinoActivityIndicator(color: Colors.white),
                  ),
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
                child: ctrl.buildPlayer(
                  preferWarmPoolPauseOnAndroid: true,
                  preferStableStartupBuffer:
                      defaultTargetPlatform == TargetPlatform.android,
                ),
              ),
              AnimatedBuilder(
                animation: ctrl,
                builder: (_, __) {
                  final value = ctrl.value;
                  final hasStableVideoFrame = value.hasRenderedFirstFrame &&
                      !value.isBuffering &&
                      (value.isPlaying ||
                          value.position > const Duration(milliseconds: 180));
                  return IgnorePointer(
                    ignoring: true,
                    child: AnimatedOpacity(
                      opacity: hasStableVideoFrame ? 0 : 1,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: _buildThumb(widget.startList[idx]),
                    ),
                  );
                },
              ),
              // Henüz hazır değilse loading overlay
              if (!isReady)
                if (widget.startList[idx].thumbnail.trim().isEmpty)
                  const Center(
                    child: CupertinoActivityIndicator(color: Colors.white),
                  ),
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
