part of 'post_creator_controller.dart';

extension _PostCreatorControllerUiX on PostCreatorController {
  void _uploadAllPostsInBackground() async {
    if (!_validateCaptionLengths()) {
      return;
    }

    final progressController = ensureUploadProgressController();
    final allImages = <File>[];
    final allVideos = <File>[];

    for (final postModel in postList) {
      final tag = postModel.index.toString();
      final c = ensureCreatorContentController(tag: tag);
      allImages.addAll(c.selectedImages);
      if (c.selectedVideo.value != null) {
        allVideos.add(c.selectedVideo.value!);
      }
      final validation = await UploadValidationService.validatePost(
        images: c.selectedImages.toList(),
        videos:
            c.selectedVideo.value != null ? [c.selectedVideo.value!] : <File>[],
        text: (c.reusedVideoUrl.value.trim().isNotEmpty ||
                c.reusedImageUrls.isNotEmpty)
            ? 'media'
            : c.textEdit.text.trim(),
        maxTextLength: PostCaptionLimits.forCurrentUser(),
      );

      if (!validation.isValid) {
        UploadValidationService.showValidationError(validation.errorMessage!);
        return;
      }
    }

    final validation = UploadValidationService.validateTotalPostSize(
      allImages,
      allVideos,
    );

    if (!validation.isValid) {
      UploadValidationService.showValidationError(validation.errorMessage!);
      return;
    }

    Get.back();

    final totalPosts = postList.length;
    progressController.startProgress(
      total: totalPosts,
      initialStatus: 'post_creator.preparing_posts'.tr,
    );

    final nav = _maybeNavBarController();
    nav?.uploadingPosts.value = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uploadedPosts = await uploadAllPosts(progressController);

      if (uploadedPosts.isNotEmpty) {
        final agendaController = maybeFindAgendaController();
        await Future.delayed(const Duration(milliseconds: 150));
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final nowPosts =
            uploadedPosts.where((e) => e.timeStamp <= nowMs).toList();
        if (agendaController != null && nowPosts.isNotEmpty) {
          final ids = nowPosts.map((e) => e.docID).toList();
          agendaController.markHighlighted(ids);
          agendaController.addUploadedPostsAtTop(nowPosts);
        }
        if (agendaController != null &&
            agendaController.scrollController.hasClients) {
          agendaController.scrollController.jumpTo(0);
        }
        await persistUploadedPostsToHomeFeed(nowPosts);
        unawaited(
          _hydrateUploadedPostShortLinks(
            nowPosts,
            agendaController: agendaController,
          ),
        );
        ProfileController.maybeFind()?.getLastPostAndAddToAllPosts();
        progressController.complete('post_creator.upload_success'.tr);
      } else {
        progressController.setError('post_creator.upload_error'.tr);
      }

      nav?.uploadingPosts.value = false;
    });
  }

  Future<void> _showCommentOptions() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Obx(() {
          Widget optionTile({
            required String title,
            required IconData icon,
            required bool selected,
            required VoidCallback onTap,
          }) {
            return GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.white.withAlpha(1),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'post_creator.comments.title'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'post_creator.comments.subtitle'.tr,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontFamily: "MontserratMedium",
                ),
              ),
              const SizedBox(height: 14),
              optionTile(
                title: 'post_creator.comments.everyone'.tr,
                icon: CupertinoIcons.globe,
                selected: commentVisibility.value == 0,
                onTap: () {
                  commentVisibility.value = 0;
                  comment.value = true;
                },
              ),
              optionTile(
                title: 'post_creator.comments.verified'.tr,
                icon: CupertinoIcons.checkmark_seal,
                selected: commentVisibility.value == 1,
                onTap: () {
                  commentVisibility.value = 1;
                  comment.value = true;
                },
              ),
              optionTile(
                title: 'post_creator.comments.following'.tr,
                icon: CupertinoIcons.person_2,
                selected: commentVisibility.value == 2,
                onTap: () {
                  commentVisibility.value = 2;
                  comment.value = true;
                },
              ),
              optionTile(
                title: 'post_creator.comments.closed'.tr,
                icon: CupertinoIcons.chat_bubble_text,
                selected: commentVisibility.value == 3,
                onTap: () {
                  commentVisibility.value = 3;
                  comment.value = false;
                },
              ),
            ],
          );
        }),
      ),
    );
  }
}
