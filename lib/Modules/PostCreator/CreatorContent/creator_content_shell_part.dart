part of 'creator_content.dart';

extension CreatorContentShellPart on CreatorContent {
  Widget _buildComposer(BuildContext context) {
    controller = CreatorContentController.ensure(
      tag: model.index.toString(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () {
          if (!isSelected) {
            final position = mainController.postList.indexWhere(
              (post) => post.index == model.index,
            );
            if (position != -1) {
              mainController.selectedIndex.value = position;
            }
          }
          controller.focus.requestFocus();
        },
        child: Obx(() {
          final userService = CurrentUserService.instance;
          final currentUser = userService.currentUserRx.value;
          final threadIndex = mainController.postList.indexWhere(
            (post) => post.index == model.index,
          );
          final isFirstInThread = threadIndex <= 0;
          final isLastInThread = threadIndex == -1 ||
              threadIndex == mainController.postList.length - 1;
          final composerUserId =
              (currentUser?.userID ?? userService.effectiveUserId).trim();
          final composerAvatarUrl =
              (currentUser?.avatarUrl ?? userService.avatarUrl).trim();
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (mainController.postList.length > 1)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 2,
                            margin: EdgeInsets.only(
                              top: isFirstInThread ? 44 : 0,
                              bottom: isLastInThread ? 12 : 0,
                            ),
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: CachedUserAvatar(
                              userId: composerUserId.isNotEmpty
                                  ? composerUserId
                                  : null,
                              imageUrl: composerAvatarUrl.isNotEmpty
                                  ? composerAvatarUrl
                                  : null,
                              radius: 19,
                            ),
                          ),
                          7.ph,
                        ],
                      ),
                    ),
                  ],
                ),
                4.pw,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textBody(),
                      const SizedBox(height: 12),
                      Obx(() {
                        final hasMedia = controller.croppedImages.isNotEmpty ||
                            controller.selectedImages.isNotEmpty ||
                            controller.reusedImageUrls.isNotEmpty ||
                            controller.videoPlayerController != null ||
                            controller.waitingVideo.value;
                        if (mainController.isQuotedPost ||
                            mainController.postList.length > 1) {
                          return const SizedBox.shrink();
                        }
                        return hasMedia
                            ? Padding(
                                padding: EdgeInsets.only(
                                  top: 10,
                                  left: (controller.videoPlayerController !=
                                              null ||
                                          controller.waitingVideo.value)
                                      ? 7
                                      : 0,
                                ),
                                child: _buildMediaLookSelector(),
                              )
                            : const SizedBox.shrink();
                      }),
                      Obx(() {
                        final hasMedia = controller.croppedImages.isNotEmpty ||
                            controller.selectedImages.isNotEmpty ||
                            controller.reusedImageUrls.isNotEmpty ||
                            controller.videoPlayerController != null ||
                            controller.waitingVideo.value;
                        if (mainController.isQuotedPost) {
                          return const SizedBox.shrink();
                        }
                        return hasMedia
                            ? const SizedBox.shrink()
                            : buildPollPreview();
                      }),
                      Obx(() {
                        if (mainController.isQuotedPost) {
                          return _buildQuotedComposerCard();
                        }
                        final imagePreviewBytes = _currentImagePreviewBytes();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imagePreviewBytes.isNotEmpty)
                              _buildThreadPickerPreview(
                                buildImageGridFromMemory(
                                  imagePreviewBytes,
                                ),
                              ),
                            if (imagePreviewBytes.isEmpty &&
                                controller.reusedImageUrls.isNotEmpty)
                              _buildThreadPickerPreview(
                                buildImageGridFromUrls(
                                  controller.reusedImageUrls,
                                ),
                              ),
                            _buildThreadPickerPreview(
                              Stack(
                                children: [
                                  if (!controller.waitingVideo.value &&
                                      controller.videoPlayerController != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 7),
                                      child: videoBody(),
                                    ),
                                  if (controller.waitingVideo.value)
                                    AspectRatio(
                                      aspectRatio: 1,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey.shade300,
                                            highlightColor:
                                                Colors.grey.shade100,
                                            child: Container(
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child:
                                                    CupertinoActivityIndicator(
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                'post_creator.video_processing'
                                                    .tr,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                  fontFamily:
                                                      "MontserratMedium",
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                      Obx(() {
                        final hasMedia = controller.croppedImages.isNotEmpty ||
                            controller.reusedImageUrls.isNotEmpty ||
                            controller.videoPlayerController != null ||
                            controller.waitingVideo.value;
                        if (mainController.isQuotedPost) {
                          return const SizedBox.shrink();
                        }
                        return hasMedia
                            ? Padding(
                                padding: EdgeInsets.only(
                                  top: 12,
                                  left: (controller.videoPlayerController !=
                                              null ||
                                          controller.waitingVideo.value)
                                      ? 7
                                      : 0,
                                ),
                                child: buildPollPreview(),
                              )
                            : const SizedBox.shrink();
                      }),
                      12.ph,
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
