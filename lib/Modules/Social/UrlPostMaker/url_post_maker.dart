import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Helpers/ImagePreview/image_preview.dart';
import 'package:turqappv2/Core/Widgets/shared_post_label.dart';
import 'package:turqappv2/Modules/Social/UrlPostMaker/url_post_maker_controller.dart';

class UrlPostMaker extends StatelessWidget {
  final String video;
  final List<String> imgs;
  final double aspectRatio;
  final String thumbnail;
  final String? originalUserID;
  final String? originalPostID;
  final bool sharedAsPost;

  UrlPostMaker({
    super.key,
    required this.video,
    required this.aspectRatio,
    required this.imgs,
    required this.thumbnail,
    this.originalUserID,
    this.originalPostID,
    this.sharedAsPost = false,
  });

  final controller = Get.put(UrlPostMakerController());

  void _initVideo() {
    if (video.isNotEmpty && controller.videoPlayerController.value == null) {
      controller.getReadyVideoPlayer(video);
    }
  }

  @override
  Widget build(BuildContext context) {
    _initVideo();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BackButtons(text: "Yeni Gönderi"),
                          Obx(() => GestureDetector(
                                onTap: controller.isSharing.value
                                    ? null
                                    : () {
                                        controller.setData(
                                          imgs,
                                          video,
                                          thumbnail,
                                          aspectRatio,
                                          originalUserID: originalUserID,
                                          originalPostID: originalPostID,
                                          sharedAsPost: sharedAsPost,
                                        );
                                      },
                                child: Text(
                                  "Paylaş",
                                  style: TextStyle(
                                      color: controller.isSharing.value
                                          ? Colors.grey
                                          : Colors.blueAccent,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium"),
                                ),
                              ))
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: controller.textEditingController,
                          maxLength: 100,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Gönderi metini oluştur",
                            hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                                fontSize: 15),
                            counterText: "",
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Obx(() {
                      return controller.adres.value != ""
                          ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 15, right: 15, bottom: 15),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.map_pin,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  Expanded(
                                    child: Text(
                                      controller.adres.value,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium"),
                                    ),
                                  )
                                ],
                              ),
                            )
                          : SizedBox();
                    }),
                    videobody(),
                    if (imgs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(
                                () => ImagePreview(imgs: imgs, startIndex: 0));
                          },
                          child: buildImageGrid(imgs),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            toolbar()
          ],
        ),
      ),
    );
  }

  Widget videobody() {
    return Obx(() {
      final ctrl = controller.videoPlayerController.value;
      if (ctrl != null && ctrl.value.isInitialized) {
        final videoWidth = ctrl.value.size.width;
        final videoHeight = ctrl.value.size.height;
        return Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: videoWidth,
                      height: videoHeight,
                      child: ctrl.buildPlayer(),
                    ),
                  ),
                  // Sağ alt köşe play/pause butonu
                  if (sharedAsPost && (originalUserID ?? '').isNotEmpty)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: SharedPostLabel(
                        originalUserID: originalUserID!,
                        textColor: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Obx(() => GestureDetector(
                          onTap: () {
                            if (controller.isPlaying.value) {
                              ctrl.pause();
                            } else {
                              ctrl.play();
                            }
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              controller.isPlaying.value
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        )),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return Container();
    });
  }

  Widget buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    final outerRadius = BorderRadius.circular(12);

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        GestureDetector(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: outerRadius,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImageContent(images),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent(List<String> images) {
    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: aspectRatio,
          child: _buildImage(images[0], radius: BorderRadius.circular(12)),
        );
      case 2:
        return _buildTwoImageGrid(images);
      case 3:
        return _buildThreeImageGrid(images);
      case 4:
      default:
        return buildFourImageGrid(images);
    }
  }

  Widget buildFourImageGrid(List<String> images) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemBuilder: (context, index) {
        final radius = _getGridRadius(index);
        return _buildImage(images[index], radius: radius);
      },
    );
  }

  Widget _buildThreeImageGrid(List<String> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildImage(
                  images[0],
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              SizedBox(width: 1),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildImage(
                        images[1],
                        radius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 1),
                    Expanded(
                      child: _buildImage(
                        images[2],
                        radius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTwoImageGrid(List<String> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size,
          child: Row(
            children: [
              Expanded(
                child: _buildImage(
                  images[0],
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              SizedBox(width: 1),
              Expanded(
                child: _buildImage(
                  images[1],
                  radius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(String url, {required BorderRadius radius}) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => const CupertinoActivityIndicator(),
        ),
      ),
    );
  }

  BorderRadius _getGridRadius(int index) {
    switch (index) {
      case 0:
        return const BorderRadius.only(topLeft: Radius.circular(12));
      case 1:
        return const BorderRadius.only(topRight: Radius.circular(12));
      case 2:
        return const BorderRadius.only(bottomLeft: Radius.circular(12));
      case 3:
        return const BorderRadius.only(bottomRight: Radius.circular(12));
      default:
        return BorderRadius.zero;
    }
  }

  Widget toolbar() {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  IconButton(
                    onPressed: controller.goToLocationMap,
                    icon: const Icon(
                      CupertinoIcons.map_pin_ellipse,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: controller.showCommentOptions,
                    icon: const Icon(
                      CupertinoIcons.ellipses_bubble,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
