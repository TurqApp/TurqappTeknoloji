part of 'story_circle.dart';

extension _StoryCircleContentPart on _StoryCircleState {
  Widget _buildStoryCircle(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: _StoryCircleState._storyCircleSize,
          height: _StoryCircleState._storyCircleSize,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: _handleTap,
                onLongPress: _handleLongPress,
                child: _buildStoryAvatar(context),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: (_currentUid.isNotEmpty &&
                        widget.model.userID == _currentUid)
                    ? GestureDetector(
                        onTap: _openStoryMaker,
                        child: Container(
                          width: _StoryCircleState._addBadgeSize,
                          height: _StoryCircleState._addBadgeSize,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: const Icon(
                            CupertinoIcons.add,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: _StoryCircleState._labelWidth,
          child: Text(
            widget.model.nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              height: 1,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleTap() async {
    final cont = AgendaController.maybeFind();
    final prevIndex = cont?.lastCenteredIndex;
    cont?.lastCenteredIndex = prevIndex;
    cont?.centeredIndex.value = -1;
    final myUserID = _currentUid;
    final isMe = myUserID.isNotEmpty && widget.model.userID == myUserID;

    if (isMe) {
      final hasMyStory = widget.model.stories.isNotEmpty;
      if (hasMyStory) {
        await Get.to(
          () => StoryViewer(
            startedUser: widget.model,
            storyOwnerUsers: widget.users,
          ),
        );
      } else {
        await Get.to(() => StoryMaker());
      }
    } else {
      await Get.to(
        () => StoryViewer(
          startedUser: widget.model,
          storyOwnerUsers: widget.users,
        ),
      );
    }

    if (cont != null) {
      cont.resumeFeedPlayback();
    }
  }

  void _handleLongPress() {
    final myId = _currentUid;
    final isMe = myId.isNotEmpty && widget.model.userID == myId;
    if (!isMe) return;

    final agenda = AgendaController.maybeFind();
    final prevIndex = agenda?.lastCenteredIndex;
    if (agenda != null) {
      agenda.lastCenteredIndex = prevIndex;
      agenda.centeredIndex.value = -1;
      agenda.pauseAll.value = true;
    }
    if (DeletedStoriesController.maybeFind() != null) {
      Get.delete<DeletedStoriesController>(force: true);
    }
    Get.to(() => const DeletedStoriesView())?.then((_) {
      if (agenda != null) {
        agenda.pauseAll.value = false;
        agenda.resumeFeedPlayback();
      }
    });
  }

  void _openStoryMaker() {
    final cont = AgendaController.maybeFind();
    final prevIndex = cont?.lastCenteredIndex;
    cont?.lastCenteredIndex = prevIndex;
    cont?.centeredIndex.value = -1;

    Get.to(() => StoryMaker())?.then((_) {
      if (cont != null) {
        cont.resumeFeedPlayback();
      }
    });
  }

  Widget _buildStoryAvatar(BuildContext context) {
    return Obx(() {
      final myId = _currentUid;
      final isMe = myId.isNotEmpty && widget.model.userID == myId;
      final hasStory = widget.model.stories.isNotEmpty;
      final allSeen = _storyOptimizer.areAllStoriesSeenCached(
        widget.model.userID,
        widget.model.stories,
      );
      final uploading = StoryMakerController.isUploadingStory.value;
      final isUploading = isMe && uploading;
      final highlight = hasStory && !allSeen;

      final baseRingDecoration = BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withAlpha(20),
        border: Border.all(color: Colors.grey.withAlpha(50), width: 2),
      );

      const highlightRingDecoration = ShapeDecoration(
        shape: CircleBorder(),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB7D8FF),
            Color(0xFF6EB6FF),
            Color(0xFF2C8DFF),
            Color(0xFF0E5BFF),
          ],
        ),
      );

      return Stack(
        fit: StackFit.expand,
        children: [
          if (widget.isFirst && hasStory)
            Positioned(
              left: -34,
              top: (_StoryCircleState._storyCircleSize / 2) - 2,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 30),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, width, child) {
                  return Container(
                    width: width,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFB7D8FF).withAlpha(0),
                          const Color(0xFF6EB6FF),
                          const Color(0xFF0E5BFF),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Container(
            decoration:
                highlight ? highlightRingDecoration : baseRingDecoration,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _buildAvatarImage(isMe: isMe),
                ),
              ),
            ),
          ),
          if (isUploading) const Positioned.fill(child: StoryUploadingRing()),
        ],
      );
    });
  }

  Widget _buildAvatarImage({required bool isMe}) {
    final imageUrl = isMe ? userService.avatarUrl : widget.model.avatarUrl;
    return ClipRect(
      child: CachedUserAvatar(
        userId: widget.model.userID,
        imageUrl: imageUrl,
        radius: _StoryCircleState._storyAvatarRadius,
        backgroundColor: Colors.transparent,
        placeholder: const DefaultAvatar(
          radius: _StoryCircleState._storyAvatarRadius,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
