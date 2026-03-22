part of 'post_creator.dart';

extension PostCreatorToolbarPart on PostCreator {
  Widget _buildToolbar() {
    return Obx(() {
      final mediaQuery = MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.first,
      );
      final keyboardInset = mediaQuery.viewInsets.bottom;
      final selectedListIndex = controller.selectedIndex.value.clamp(
        0,
        controller.postList.length - 1,
      );
      final selectedModel = controller.postList[selectedListIndex];
      final selectedController =
          controller.ensureComposerControllerFor(selectedModel.index);

      if (selectedController.waitingVideo.value) {
        return const SizedBox.shrink();
      }

      final hasImages = selectedController.croppedImages.isNotEmpty ||
          selectedController.selectedImages.isNotEmpty ||
          selectedController.reusedImageUrls.isNotEmpty;
      final hasVideo = selectedController.selectedVideo.value != null;
      final hasCaption = selectedController.textChanged.value ||
          selectedController.textEdit.text.trim().isNotEmpty;
      final commentActive = controller.commentVisibility.value != 0;
      final reshareActive = controller.paylasimSelection.value != 0;
      final pollActive = selectedController.pollData.value != null &&
          (selectedController.pollData.value?['options'] is List) &&
          (selectedController.pollData.value!['options'] as List).isNotEmpty;
      final disableFirstThree = controller.isEditMode.value;
      final disableFlood = controller.isEditMode.value ||
          !(hasCaption || hasImages || hasVideo || pollActive);
      final iconGap = AppIconSurface.kGap - 1;
      final toolbarIconSize = AppIconSurface.kIconSize;
      final compactButtonSize = GetPlatform.isIOS ? 30.0 : 29.0;
      final bottomPadding = keyboardInset > 0 ? 6.0 : 14.0;

      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          bottom: bottomPadding,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _toolbarSlot(
                      child: _toolbarSurfaceButton(
                        onPressed: disableFirstThree
                            ? null
                            : selectedController.pickImage,
                        size: compactButtonSize,
                        icon: Icon(
                          CupertinoIcons.photo_on_rectangle,
                          size: toolbarIconSize,
                          color: disableFirstThree
                              ? Colors.black38
                              : (hasImages ? Colors.blueAccent : Colors.black),
                        ),
                      ),
                    ),
                    _toolbarSlot(
                      child: _toolbarSurfaceButton(
                        onPressed: disableFirstThree
                            ? null
                            : () {
                                selectedController.pickVideo(
                                  source: ImageSource.gallery,
                                );
                              },
                        size: compactButtonSize,
                        icon: Icon(
                          CupertinoIcons.play_circle,
                          size: toolbarIconSize,
                          color: disableFirstThree
                              ? Colors.black38
                              : (hasVideo ? Colors.blueAccent : Colors.black),
                        ),
                      ),
                    ),
                    _toolbarSlot(
                      child: _toolbarSurfaceButton(
                        onPressed: disableFirstThree
                            ? null
                            : selectedController.openCustomCameraCapture,
                        size: compactButtonSize,
                        icon: Icon(
                          CupertinoIcons.camera,
                          size: toolbarIconSize,
                          color:
                              disableFirstThree ? Colors.black38 : Colors.black,
                        ),
                      ),
                    ),
                    _toolbarSlot(
                      child: _toolbarSurfaceButton(
                        onPressed: selectedController.openPollComposer,
                        size: compactButtonSize,
                        icon: Icon(
                          CupertinoIcons.chart_bar,
                          size: toolbarIconSize,
                          color: pollActive ? Colors.blueAccent : Colors.black,
                        ),
                      ),
                    ),
                    _toolbarSlot(
                      child: PullDownButton(
                        itemBuilder: (context) => [
                          PullDownMenuItem(
                            onTap: () {
                              controller.commentVisibility.value = 0;
                              controller.comment.value = true;
                            },
                            title: 'post_creator.comments.everyone'.tr,
                            icon: controller.commentVisibility.value == 0
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                          ),
                          PullDownMenuItem(
                            onTap: () {
                              controller.commentVisibility.value = 1;
                              controller.comment.value = true;
                            },
                            title: 'post_creator.comments.verified'.tr,
                            icon: controller.commentVisibility.value == 1
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                          ),
                          PullDownMenuItem(
                            onTap: () {
                              controller.commentVisibility.value = 2;
                              controller.comment.value = true;
                            },
                            title: 'post_creator.comments.following'.tr,
                            icon: controller.commentVisibility.value == 2
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                          ),
                          PullDownMenuItem(
                            onTap: () {
                              controller.commentVisibility.value = 3;
                              controller.comment.value = false;
                            },
                            title: 'post_creator.comments.closed'.tr,
                            icon: controller.commentVisibility.value == 3
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                          ),
                        ],
                        buttonBuilder: (context, showMenu) =>
                            _toolbarSurfaceButton(
                          onPressed: showMenu,
                          size: compactButtonSize,
                          icon: Icon(
                            CupertinoIcons.bubble_right,
                            size: toolbarIconSize,
                            color: commentActive
                                ? Colors.blueAccent
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    _toolbarSlot(
                      child: PullDownButton(
                        itemBuilder: (context) => [
                          PullDownMenuItem(
                            onTap: () {
                              controller.paylasimSelection.value = 0;
                            },
                            title: 'post_creator.reshare.everyone'.tr,
                            icon: controller.paylasimSelection.value == 0
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                          ),
                          PullDownMenuItem(
                            onTap: () {
                              controller.paylasimSelection.value = 1;
                            },
                            title: 'post_creator.reshare.verified'.tr,
                            icon: controller.paylasimSelection.value == 1
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                          ),
                          PullDownMenuItem(
                            onTap: () {
                              controller.paylasimSelection.value = 2;
                            },
                            title: 'post_creator.reshare.following'.tr,
                            icon: controller.paylasimSelection.value == 2
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                          ),
                          PullDownMenuItem(
                            onTap: () {
                              controller.paylasimSelection.value = 3;
                            },
                            title: 'post_creator.reshare.closed'.tr,
                            icon: controller.paylasimSelection.value == 3
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                          ),
                        ],
                        buttonBuilder: (context, showMenu) =>
                            _toolbarSurfaceButton(
                          onPressed: showMenu,
                          size: compactButtonSize,
                          icon: Icon(
                            Icons.repeat,
                            size: toolbarIconSize,
                            color: reshareActive
                                ? Colors.blueAccent
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    _toolbarSlot(
                      child: Obx(() {
                        final scheduled = controller.publishMode.value == 1;
                        return _toolbarSurfaceButton(
                          onPressed: () {
                            if (scheduled) {
                              noYesAlert(
                                title: 'post_creator.schedule.remove_title'.tr,
                                message:
                                    'post_creator.schedule.remove_message'.tr,
                                yesText: 'common.remove'.tr,
                                onYesPressed: () {
                                  controller.publishMode.value = 0;
                                  controller.izBirakDateTime.value = null;
                                },
                              );
                            } else {
                              controller.showPublishModePicker();
                            }
                          },
                          size: compactButtonSize,
                          icon: Icon(
                            scheduled
                                ? CupertinoIcons.clock_fill
                                : CupertinoIcons.clock,
                            size: toolbarIconSize,
                            color: scheduled ? Colors.blueAccent : Colors.black,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              SizedBox(width: iconGap),
              TextButton(
                onPressed: disableFlood
                    ? null
                    : () {
                        final newIndex = controller.allocateComposerItemIndex();
                        controller.postList.add(
                          PostCreatorModel(index: newIndex, text: ""),
                        );
                        final newTag = newIndex.toString();
                        controller.selectedIndex.value =
                            controller.postList.length - 1;
                        final nextController =
                            CreatorContentController.ensure(tag: newTag);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!nextController.focus.hasFocus) {
                            nextController.focus.requestFocus();
                          }
                        });
                      },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  minimumSize: const Size(29, 29),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: disableFlood ? Colors.black26 : Colors.green,
                  ),
                  child: const Icon(
                    CupertinoIcons.add,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _toolbarSurfaceButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required double size,
  }) {
    final isDisabled = onPressed == null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1,
        child: AppIconSurface(
          size: size,
          radius: AppIconSurface.kRadius,
          child: icon,
        ),
      ),
    );
  }

  Widget _toolbarSlot({required Widget child}) {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
