part of 'creator_content.dart';

extension CreatorContentQuotedPart on CreatorContent {
  Widget _buildQuotedComposerCard() {
    final hasImage = controller.reusedImageUrls.isNotEmpty;
    final hasVideo = controller.videoPlayerController != null ||
        controller.waitingVideo.value;
    final quotedText = mainController.quotedOriginalText.trim();
    if (!hasImage && !hasVideo && quotedText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9DEE5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuotedComposerSourceHeader(),
                if (quotedText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    quotedText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF3A434D),
                      fontSize: 14,
                      height: 1.35,
                      fontFamily: "Montserrat",
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasImage)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        _buildImageContentFromUrls(controller.reusedImageUrls),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _buildQuotedRemoveButton(),
                  ),
                ],
              ),
            )
          else if (hasVideo)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: controller.waitingVideo.value
                  ? Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CupertinoActivityIndicator(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'post_creator.video_processing'.tr,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _buildQuotedRemoveButton(),
                        ),
                      ],
                    )
                  : videoBody(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuotedRemoveButton() {
    return GestureDetector(
      onTap: () {
        final tag = mainController.selectedIndex.value.toString();
        final targetController = CreatorContentController.maybeFind(tag: tag);
        if (targetController == null) return;
        targetController.selectedImages.clear();
        targetController.croppedImages.clear();
        targetController.reusedImageUrls.clear();
        if (targetController.videoPlayerController != null) {
          targetController.videoPlayerController!.pause();
          targetController.videoPlayerController!.dispose();
          targetController.rxVideoPlayerController.value = null;
        }
        targetController.selectedVideo.value = null;
        targetController.reusedVideoUrl.value = '';
        targetController.reusedVideoThumbnail.value = '';
        targetController.reusedVideoAspectRatio.value = 0.0;
        targetController.waitingVideo.value = false;
        targetController.isPlaying.value = false;
        targetController.hasVideo.value = false;
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildQuotedComposerSourceHeader() {
    final sourceUserId = mainController.quotedSourceUserID.trim().isNotEmpty
        ? mainController.quotedSourceUserID.trim()
        : mainController.sharedOriginalUserID.trim();
    final sourcePostId = mainController.sharedOriginalPostID.trim();
    if (sourceUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    final profileCache = UserProfileCacheService.ensure();
    final postRepository = PostRepository.ensure();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        profileCache.getProfile(
          sourceUserId,
          preferCache: true,
          cacheOnly: false,
        ),
        if (sourcePostId.isNotEmpty)
          postRepository.fetchPostCardsByIds([sourcePostId])
        else
          Future.value(null),
      ]),
      builder: (context, snapshot) {
        final profile = (snapshot.data != null && snapshot.data!.isNotEmpty
                ? snapshot.data!.first
                : null) as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final sourcePostMap = snapshot.data != null && snapshot.data!.length > 1
            ? snapshot.data![1] as Map<String, PostsModel>?
            : null;
        final sourcePostData =
            sourcePostMap?[sourcePostId]?.toMap() ?? const <String, dynamic>{};
        final displayName = (profile['fullName'] ??
                profile['nickname'] ??
                profile['displayName'] ??
                profile['name'] ??
                sourcePostData['authorNickname'] ??
                sourcePostData['nickname'] ??
                profile['username'] ??
                'common.user'.tr)
            .toString()
            .trim();
        final username =
            (profile['username'] ?? sourcePostData['authorNickname'] ?? '')
                .toString()
                .trim();
        final avatarUrl =
            (profile['avatarUrl'] ?? sourcePostData['authorAvatarUrl'] ?? '')
                .toString()
                .trim();
        final sourceTime = ((sourcePostData['izBirakYayinTarihi'] ??
                    sourcePostData['timeStamp']) ??
                0)
            .toString();
        final sourceTimeStamp =
            num.tryParse(sourceTime) ?? (sourcePostData['timeStamp'] ?? 0);
        final displayTime = sourceTimeStamp == 0
            ? ''
            : timeAgoMetin(sourceTimeStamp).toString();

        return Row(
          children: [
            CachedUserAvatar(
              userId: sourceUserId,
              imageUrl: avatarUrl,
              radius: 20,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName.isEmpty ? 'common.user'.tr : displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                  if (username.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontFamily: "Montserrat",
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  RozetContent(size: 13, userID: sourceUserId),
                  if (displayTime.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        displayTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildPollPreview() {
    return Obx(() {
      final poll = controller.pollData.value;
      if (poll == null || poll.isEmpty) return const SizedBox.shrink();
      final options = (poll['options'] is List) ? poll['options'] as List : [];
      if (options.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(options.length, (i) {
            final text = (options[i]['text'] ?? '').toString();
            final label = '${String.fromCharCode(65 + i)}) ';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '$label$text',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontFamily: "MontserratMedium",
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}
