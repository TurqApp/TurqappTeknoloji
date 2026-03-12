import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/PostCreator/CreatorContent/creator_content_controller.dart';
import 'package:turqappv2/Modules/PostCreator/CreatorContent/post_creator_model.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'CreatorContent/creator_content.dart';
import 'post_creator_controller.dart';
import '../../Core/BottomSheets/no_yes_alert.dart';
import '../../Core/Widgets/progress_indicators.dart';

class PostCreator extends StatelessWidget {
  final String sharedVideoUrl;
  final List<String> sharedImageUrls;
  final double sharedAspectRatio;
  final String sharedThumbnail;
  final bool sharedAsPost;
  final String? originalUserID;
  final String? originalPostID;
  final bool quotedPost;
  final String? quotedOriginalText;
  final String? quotedSourceUserID;
  final bool editMode;
  final PostsModel? editPost;

  PostCreator({
    super.key,
    this.sharedVideoUrl = '',
    this.sharedImageUrls = const <String>[],
    this.sharedAspectRatio = 9 / 16,
    this.sharedThumbnail = '',
    this.sharedAsPost = false,
    this.originalUserID,
    this.originalPostID,
    this.quotedPost = false,
    this.quotedOriginalText,
    this.quotedSourceUserID,
    this.editMode = false,
    this.editPost,
  });
  final controller = Get.put(PostCreatorController());
  final progressController = Get.put(UploadProgressController());

  @override
  Widget build(BuildContext context) {
    controller.applySharedSourceIfNeeded(
      videoUrl: sharedVideoUrl,
      imageUrls: sharedImageUrls,
      aspectRatio: sharedAspectRatio,
      thumbnail: sharedThumbnail,
      sharedAsPost: sharedAsPost,
      originalUserID: originalUserID,
      originalPostID: originalPostID,
      quotedPost: quotedPost,
      quotedOriginalText: quotedOriginalText,
      quotedSourceUserID: quotedSourceUserID,
    );
    controller.applyEditSourceIfNeeded(
      editMode: editMode,
      editPost: editPost,
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return Stack(
            children: [
              Column(
                children: [
                  header(context),
                  postBody(),
                  toolbar(),
                ],
              ),
              // Upload progress overlay
              Positioned.fill(
                child: UploadProgressWidget(
                  controller: progressController,
                ),
              ),
              // Media processing overlay removed
            ],
          );
        }),
      ),
    );
  }

  Widget header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              InkWell(
                onTap: () async {
                  if (controller.isSavingEdit.value) return;
                  if (controller.isEditMode.value) {
                    final ok = await controller.savePostEdit();
                    if (ok) {
                      final popped = await Navigator.of(context).maybePop();
                      if (!popped) {
                        if (Navigator.of(context, rootNavigator: true)
                            .canPop()) {
                          Navigator.of(context, rootNavigator: true).pop();
                        } else {
                          Get.back();
                        }
                      }
                    }
                    return;
                  }
                  controller.uploadAllPostsInBackgroundWithErrorHandling();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.secondColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    controller.isEditMode.value
                        ? (controller.isSavingEdit.value
                            ? "Kaydediliyor..."
                            : "Kaydet")
                        : "Yayınla",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ),
            ],
          ),
          Text(
            controller.isEditMode.value
                ? "Gönderi Düzenle"
                : "${controller.postList.length > 1 ? "Flood" : "Gönderi"} Hazırla",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: "MontserratBold",
            ),
          ),
        ],
      ),
    );
  }

  Widget postBody() {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.only(top: controller.postList.isNotEmpty ? 15 : 0),
        itemCount: controller.postList.length,
        itemBuilder: (context, index) {
          return Obx(() {
            final isSelected = controller.selectedIndex.value == index;
            // Ensure controller for this index is registered
            final tag = index.toString();
            if (!Get.isRegistered<CreatorContentController>(tag: tag)) {
              Get.put(CreatorContentController(), tag: tag);
            }
            return GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: isSelected
                  ? null
                  : () => controller.selectedIndex.value = index,
              child: Padding(
                padding: EdgeInsets.only(top: index == 0 ? 15 : 0),
                child: Stack(
                  children: [
                    CreatorContent(
                      model: controller.postList[index],
                      isSelected: isSelected,
                    ),
                    if (!isSelected)
                      Positioned.fill(
                        child: Container(
                            color: Colors.white.withValues(alpha: 0.70)),
                      ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget toolbar() {
    return Obx(() {
      final tag = controller.selectedIndex.value.toString();

      // Make sure a CreatorContentController exists for the selected index
      if (!Get.isRegistered<CreatorContentController>(tag: tag)) {
        Get.put(CreatorContentController(), tag: tag);
      }
      final selectedController = Get.find<CreatorContentController>(tag: tag);

      // Hide toolbar while video is processing
      if (selectedController.waitingVideo.value) {
        return const SizedBox.shrink();
      }

      final hasImages = selectedController.croppedImages.isNotEmpty ||
          selectedController.selectedImages.isNotEmpty ||
          selectedController.reusedImageUrls.isNotEmpty;
      final hasVideo = selectedController.selectedVideo.value != null;
      final hasLocation = selectedController.adres.value.trim().isNotEmpty;
      final commentActive = controller.commentVisibility.value != 0;
      final reshareActive = controller.paylasimSelection.value != 0;
      final pollActive = selectedController.pollData.value != null &&
          (selectedController.pollData.value?['options'] is List) &&
          (selectedController.pollData.value!['options'] as List).isNotEmpty;
      final disableFirstThree = controller.isEditMode.value;
      final disableFlood = controller.isEditMode.value;

      const double toolbarIconSize = 23.3; // ~3% smaller than 24
      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: disableFirstThree
                                  ? null
                                  : selectedController.pickImage,
                              iconSize: toolbarIconSize,
                              icon: Icon(
                                CupertinoIcons.photo_on_rectangle,
                                color: disableFirstThree
                                    ? Colors.black38
                                    : (hasImages
                                        ? Colors.blueAccent
                                        : Colors.black),
                              ),
                            ),
                            IconButton(
                              onPressed: disableFirstThree
                                  ? null
                                  : () {
                                      selectedController.pickVideo(
                                          source: ImageSource.gallery);
                                    },
                              iconSize: toolbarIconSize,
                              icon: Icon(
                                CupertinoIcons.play_circle,
                                color: disableFirstThree
                                    ? Colors.black38
                                    : (hasVideo
                                        ? Colors.blueAccent
                                        : Colors.black),
                              ),
                            ),
                            IconButton(
                              onPressed: disableFirstThree
                                  ? null
                                  : selectedController.openCustomCameraCapture,
                              iconSize: toolbarIconSize,
                              icon: Icon(
                                CupertinoIcons.camera,
                                color: disableFirstThree
                                    ? Colors.black38
                                    : Colors.black,
                              ),
                            ),
                            IconButton(
                              onPressed: selectedController.openPollComposer,
                              iconSize: toolbarIconSize,
                              icon: Icon(
                                CupertinoIcons.chart_bar,
                                color: pollActive
                                    ? Colors.blueAccent
                                    : Colors.black,
                              ),
                            ),
                            IconButton(
                              onPressed: selectedController.goToLocationMap,
                              iconSize: toolbarIconSize,
                              icon: Icon(
                                CupertinoIcons.map_pin_ellipse,
                                color: hasLocation
                                    ? Colors.blueAccent
                                    : Colors.black,
                              ),
                            ),
                            PullDownButton(
                              itemBuilder: (context) => [
                                PullDownMenuItem(
                                  onTap: () {
                                    controller.commentVisibility.value = 0;
                                    controller.comment.value = true;
                                  },
                                  title: 'Herkes',
                                  icon: controller.commentVisibility.value == 0
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                ),
                                PullDownMenuItem(
                                  onTap: () {
                                    controller.commentVisibility.value = 1;
                                    controller.comment.value = true;
                                  },
                                  title: 'Onaylı hesaplar',
                                  icon: controller.commentVisibility.value == 1
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                ),
                                PullDownMenuItem(
                                  onTap: () {
                                    controller.commentVisibility.value = 2;
                                    controller.comment.value = true;
                                  },
                                  title: 'Takip ettiğin hesaplar',
                                  icon: controller.commentVisibility.value == 2
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                ),
                                PullDownMenuItem(
                                  onTap: () {
                                    controller.commentVisibility.value = 3;
                                    controller.comment.value = false;
                                  },
                                  title: 'Yoruma kapalı',
                                  icon: controller.commentVisibility.value == 3
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                ),
                              ],
                              buttonBuilder: (context, showMenu) =>
                                  CupertinoButton(
                                onPressed: showMenu,
                                padding: EdgeInsets.zero,
                                child: Icon(
                                  CupertinoIcons.bubble_right,
                                  color: commentActive
                                      ? Colors.blueAccent
                                      : Colors.black,
                                  size: toolbarIconSize,
                                ),
                              ),
                            ),
                            PullDownButton(
                              itemBuilder: (context) => [
                                PullDownMenuItem(
                                  onTap: () {
                                    controller.paylasimSelection.value = 0;
                                  },
                                  title: 'Herkes',
                                  icon: controller.paylasimSelection.value == 0
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                ),
                                PullDownMenuItem(
                                  onTap: () {
                                    controller.paylasimSelection.value = 1;
                                  },
                                  title: 'Onaylı hesaplar',
                                  icon: controller.paylasimSelection.value == 1
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                ),
                                PullDownMenuItem(
                                  onTap: () {
                                    controller.paylasimSelection.value = 2;
                                  },
                                  title: 'Takip ettiğin hesaplar',
                                  icon: controller.paylasimSelection.value == 2
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                ),
                                PullDownMenuItem(
                                  onTap: () {
                                    controller.paylasimSelection.value = 3;
                                  },
                                  title: 'Yeniden paylaş kapalı',
                                  icon: controller.paylasimSelection.value == 3
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                ),
                              ],
                              buttonBuilder: (context, showMenu) =>
                                  CupertinoButton(
                                onPressed: showMenu,
                                padding: EdgeInsets.zero,
                                child: Icon(
                                  Icons.repeat,
                                  color: reshareActive
                                      ? Colors.blueAccent
                                      : Colors.black,
                                  size: toolbarIconSize,
                                ),
                              ),
                            ),
                            Obx(() => IconButton(
                                  onPressed: () {
                                    if (controller.publishMode.value == 1) {
                                      noYesAlert(
                                        title: 'Planlamayı Kaldır',
                                        message:
                                            'Zamanlanmış paylaşımı kaldırmak istiyor musun? Gönderi hemen paylaşılacak.',
                                        yesText: 'Kaldır',
                                        onYesPressed: () {
                                          controller.publishMode.value = 0;
                                          controller.izBirakDateTime.value =
                                              null;
                                        },
                                      );
                                    } else {
                                      controller.showPublishModePicker();
                                    }
                                  },
                                  iconSize: toolbarIconSize,
                                  icon: Icon(
                                    controller.publishMode.value == 1
                                        ? CupertinoIcons.clock_fill
                                        : CupertinoIcons.clock,
                                    color: controller.publishMode.value == 1
                                        ? Colors.blueAccent
                                        : Colors.black,
                                  ),
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: disableFlood
                    ? null
                    : () {
                        final newIndex = controller.postList.length;
                        controller.postList.add(
                          PostCreatorModel(index: newIndex, text: ""),
                        );
                        controller.selectedIndex.value = newIndex;
                        Get.put(CreatorContentController(),
                            tag: newIndex.toString());
                      },
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: disableFlood
                        ? null
                        : LinearGradient(
                            colors: [
                              AppColors.primaryColor,
                              AppColors.secondColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: disableFlood ? Colors.black26 : null,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.add,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
