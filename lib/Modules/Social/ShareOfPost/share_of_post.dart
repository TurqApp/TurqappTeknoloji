import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/text_button_styles.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Helpers/HashtagLister/hashtag_lister.dart';
import 'package:turqappv2/Modules/Social/ShareOfPost/share_of_post_controller.dart';
import 'package:video_player/video_player.dart';
import '../../../Core/BottomSheets/future_date_picker_bottom_sheet.dart';
import '../../../Core/Helpers/GridOverlayPainter/grid_overlay_painter.dart';
import 'video_cover_selector.dart';

class ShareOfPost extends StatelessWidget {
  ShareOfPost({super.key});
  final controller = Get.put(ShareOfPostController());

  double _videoPreviewHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight * 0.32).clamp(200.0, 250.0);
  }

  double _thumbnailFrameSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 0.31).clamp(96.0, 120.0);
  }

  double _textBodyHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight * 0.19).clamp(120.0, 150.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BackButtons(text: "Yeni Oluştur"),
                      Obx(() {
                        return !controller.wait.value
                            ? TextButton(
                                onPressed: () {
                                  controller.setData();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 7),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  "Paylaş",
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                              )
                            : SizedBox();
                      }),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    return ListView(
                      controller: controller.scrollControler2,
                      children: [
                        if (controller.croppedImages.isNotEmpty)
                          imageWasSelected(),
                        if (controller.selectedVideo.value != null)
                          videoWasSelected(context),
                        textBody(context),
                        if (controller.selection.value == 3)
                          SizedBox(
                            height: 50,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Paylaşım Tarihi",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratBold",
                                        ),
                                      ),
                                      Text(
                                        "Videonuzun yayınlanacağı tarih",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "Montserrat",
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      controller.videoController?.pause();
                                      Get.bottomSheet(
                                        FutureDatePickerBottomSheet(
                                          initialDate: DateTime(
                                            DateTime.now().year,
                                            DateTime.now().month + 1,
                                            DateTime.now().day,
                                          ),
                                          withTime: true,
                                          onSelected: (v) {
                                            controller.izBirakDateTime.value =
                                                v;
                                          },
                                          title: "Yayın Tarihi",
                                        ),
                                        isScrollControlled: true,
                                      ).then((v) {
                                        controller.videoController?.play();
                                      });
                                    },
                                    child: Text(
                                      controller.izBirakDateTime.value != null
                                          ? kacGunKaldiFormatter(
                                              controller.izBirakDateTime.value!,
                                            )
                                          : "Tarih Seç",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: SizedBox(
                            height: 2,
                            child: Divider(color: Colors.grey.withAlpha(20)),
                          ),
                        ),
                        Hashtaglister(
                          onTapSelected: (hashtag) {
                            controller.textEditingController.text +=
                                " $hashtag";
                          },
                        ),
                      ],
                    );
                  }),
                ),
                bottombar(),
              ],
            ),
          ),
          Obx(() {
            return Stack(
              children: [
                if (controller.wait.value)
                  Container(
                    alignment: Alignment.center,
                    color: Colors.black.withAlpha(100),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: 2.0,
                          child: const CupertinoActivityIndicator(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Video İşleniyor",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget bottombar() {
    return Obx(() {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Row(
          children: [
            Row(
              children: [
                Wrap(
                  spacing: 10,
                  children: [
                    TextButton(
                      onPressed: () {
                        controller.selection.value = 0;
                        controller.pickImage(source: ImageSource.camera);
                      },
                      style: TextButtonStyle.textButonStyle,
                      child: Icon(
                        CupertinoIcons.camera,
                        color: controller.selection.value == 0
                            ? Colors.blueAccent
                            : Colors.black,
                        size: 25,
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, -5),
                      child: PullDownButton(
                        itemBuilder: (context) => [
                          PullDownMenuItem(
                            onTap: () {
                              controller.selection.value = 1;
                              controller.pickImage(
                                source: ImageSource.gallery,
                              );
                            },
                            title: 'Tekli Fotoğraf',
                            icon: CupertinoIcons.photo,
                          ),
                          PullDownMenuItem(
                            onTap: () {
                              controller.selection.value = 1;
                              controller.pickMultiImage();
                            },
                            title: 'Çoklu Fotoğraf',
                            icon: CupertinoIcons.photo_on_rectangle,
                          ),
                        ],
                        buttonBuilder: (context, showMenu) => CupertinoButton(
                          onPressed: showMenu,
                          padding: EdgeInsets.zero,
                          child: Icon(
                            CupertinoIcons.photo,
                            color: Colors.black,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.selection.value = 2;
                        controller.pickVideo();
                      },
                      style: TextButtonStyle.textButonStyle,
                      child: Icon(
                        CupertinoIcons.play_circle,
                        color: controller.selection.value == 2
                            ? Colors.blueAccent
                            : Colors.black,
                        size: 25,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.selection.value = 3;
                        controller.pickIzBirak();
                      },
                      style: TextButtonStyle.textButonStyle,
                      child: Transform.rotate(
                        angle: 40 * 3.141592653589793 / 180,
                        child: SizedBox(
                          width: 23,
                          height: 23,
                          child: SvgPicture.asset(
                            "assets/icons/${controller.selection.value == 3 ? "foot2" : "foot"}.svg",
                            colorFilter: ColorFilter.mode(
                              controller.selection.value == 3
                                  ? Colors.blueAccent
                                  : Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget imageWasSelected() {
    return controller.croppedImages.length >= 2
        ? AspectRatio(
            aspectRatio: 1,
            child: PageView.builder(
              itemCount: controller.croppedImages.length,
              itemBuilder: (context, index) {
                return FittedBox(
                  child: Image.memory(controller.croppedImages[index]),
                );
              },
            ),
          )
        : Image.memory(controller.croppedImages.first);
  }

  Widget videoWasSelected(BuildContext context) {
    final previewHeight = _videoPreviewHeight(context);
    final thumbnailFrame = _thumbnailFrameSize(context);
    final thumbnailInner = (thumbnailFrame - 10).clamp(88.0, 110.0);

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              children: [
                Obx(() {
                  final aspectRatio =
                      controller.videoController?.value.aspectRatio ?? 1.0;
                  final videoWidth = previewHeight * aspectRatio;

                  return Center(
                    child: SizedBox(
                      height: previewHeight,
                      width: videoWidth,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: VideoPlayer(controller.videoController!),
                            ),
                          ),
                          if (!controller.isVideoPlaying.value)
                            GestureDetector(
                              onTap: () {
                                controller.videoController!.play();
                                controller.isVideoPlaying.value = true;
                              },
                              child: Container(
                                color: Colors.black45,
                                child: const Icon(
                                  Icons.play_arrow,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () {
                                controller.videoController!.pause();
                                controller.isVideoPlaying.value = false;
                              },
                              child: Container(color: Colors.transparent),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: controller.pickVideo,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    "Yeniden Seç",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 25),
          if (controller.selectedThumbnail.value != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Çizgili arka plan (köşe L’leri)
                      SizedBox(
                        width: thumbnailFrame,
                        height: thumbnailFrame,
                        child: CustomPaint(painter: GridCornerPainter()),
                      ),

                      // Ortadaki küçük kapak
                      SizedBox(
                        width: thumbnailInner,
                        height: thumbnailInner,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            controller.selectedThumbnail.value!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () async {
                      await Get.to(
                        () => SizedBox(
                          height: Get.height * 0.5,
                          child: VideoCoverSelector(
                            listCount: controller.thumbnails.length,
                            list: controller.thumbnails.toList(),
                            onBackData: (val) {
                              controller.selectedThumbnail.value = val.file;
                              controller.selectedThumbnail.refresh();
                            },
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      "Izgara Seç",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget textBody(BuildContext context) {
    return Container(
      height: _textBodyHeight(context),
      decoration: BoxDecoration(color: Colors.grey.withAlpha(20)),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Scrollbar(
        controller: controller.scrollControler,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: controller.scrollControler,
          child: TextField(
            maxLines: null,
            focusNode: controller.textFocus.value,
            controller: controller.textEditingController,
            inputFormatters: [LengthLimitingTextInputFormatter(1000)],
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: "Gönderin hakkında bir şeyler yaz",
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: "MontserratMedium",
              ),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
      ),
    );
  }
}
