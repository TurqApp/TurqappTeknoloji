import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Helpers/ImagePreview/image_preview.dart';
import 'package:turqappv2/Core/Widgets/shared_post_label.dart';
import 'package:turqappv2/Modules/Social/UrlPostMaker/url_post_maker_controller.dart';

part 'url_post_maker_media_part.dart';
part 'url_post_maker_toolbar_part.dart';

class UrlPostMaker extends StatefulWidget {
  final String video;
  final List<String> imgs;
  final double aspectRatio;
  final String thumbnail;
  final String initialText;
  final String? originalUserID;
  final String? originalPostID;
  final bool sharedAsPost;

  const UrlPostMaker({
    super.key,
    required this.video,
    required this.aspectRatio,
    required this.imgs,
    required this.thumbnail,
    this.initialText = '',
    this.originalUserID,
    this.originalPostID,
    this.sharedAsPost = false,
  });

  @override
  State<UrlPostMaker> createState() => _UrlPostMakerState();
}

class _UrlPostMakerState extends State<UrlPostMaker> {
  late final String _tag;
  late final UrlPostMakerController controller;

  @override
  void initState() {
    super.initState();
    _tag = UniqueKey().toString();
    controller = ensureUrlPostMakerController(tag: _tag);
    controller.textEditingController.text = widget.initialText;
    if (widget.video.isNotEmpty) {
      controller.getReadyVideoPlayer(widget.video);
    }
  }

  @override
  void dispose() {
    final existing = maybeFindUrlPostMakerController(tag: _tag);
    if (identical(existing, controller)) {
      Get.delete<UrlPostMakerController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          BackButtons(text: 'post_creator.title_new'.tr),
                          Obx(() => GestureDetector(
                                onTap: controller.isSharing.value
                                    ? null
                                    : () {
                                        controller.setData(
                                          widget.imgs,
                                          widget.video,
                                          widget.thumbnail,
                                          widget.aspectRatio,
                                          originalUserID: widget.originalUserID,
                                          originalPostID: widget.originalPostID,
                                          sharedAsPost: widget.sharedAsPost,
                                        );
                                      },
                                child: Text(
                                  'common.share'.tr,
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
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'post_creator.text_hint'.tr,
                            hintStyle: const TextStyle(
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
                    if (widget.imgs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(
                              () => ImagePreview(
                                imgs: widget.imgs,
                                startIndex: 0,
                              ),
                            );
                          },
                          child: buildImageGrid(widget.imgs),
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
}
