part of 'user_story_content_controller_library.dart';

class _UserStoryContentControllerRuntimePart {
  final UserStoryContentController _controller;

  const _UserStoryContentControllerRuntimePart(this._controller);

  Future<void> getLikes(String storyID) async {
    final snapshot = await _controller._storyRepository.fetchStoryEngagement(
      storyID,
      currentUid: _controller._currentUid,
    );
    _controller.likeCount.value = snapshot.likeCount;
    _controller.isLikedMe.value = snapshot.isLiked;
    _controller.reactionCounts.assignAll(snapshot.reactionCounts);
    _controller.myReaction.value = snapshot.myReaction;
  }

  Future<void> showPostCommentsBottomSheet(
    String docID,
    String nickname,
    bool isMyStory, {
    void Function(bool)? onClosed,
  }) async {
    await Get.bottomSheet(
      SizedBox(
        height: Get.height * 0.55,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: StoryComments(
            storyID: _controller.storyID,
            nickname: nickname,
            isMyStory: isMyStory,
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
    );
    onClosed?.call(true);
  }

  Future<void> showLikesBottomSheet(
    String docID, {
    void Function(bool)? onClosed,
  }) async {
    await Get.bottomSheet(
      SizedBox(
        height: Get.height * 0.55,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: StoryLikes(storyID: _controller.storyID),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
    );
    onClosed?.call(true);
  }

  Future<void> showSeensBottomSheet(
    String docID, {
    void Function(bool)? onClosed,
  }) async {
    await Get.bottomSheet(
      SizedBox(
        height: Get.height * 0.55,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: StorySeens(storyID: _controller.storyID),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
    );
    onClosed?.call(true);
  }

  Future<void> getReactions(String storyID) async {
    try {
      final snapshot = await _controller._storyRepository.fetchStoryEngagement(
        storyID,
        currentUid: _controller._currentUid,
      );
      _controller.reactionCounts.assignAll(snapshot.reactionCounts);
      _controller.myReaction.value = snapshot.myReaction;
    } catch (e) {
      debugPrint('getReactions error: $e');
    }
  }

  Future<void> react(String storyID, String emoji) async {
    try {
      final uid = _controller._currentUid;
      if (uid.isEmpty) return;

      final previousReaction = _controller.myReaction.value;
      final nextReaction =
          await _controller._storyRepository.toggleStoryReaction(
        storyID,
        currentUid: uid,
        emoji: emoji,
        currentReaction: previousReaction,
      );

      if (previousReaction == emoji) {
        _controller.reactionCounts[emoji] =
            (_controller.reactionCounts[emoji] ?? 1) - 1;
        if (_controller.reactionCounts[emoji]! <= 0) {
          _controller.reactionCounts.remove(emoji);
        }
        _controller.myReaction.value = '';
      } else {
        if (previousReaction.isNotEmpty) {
          _controller.reactionCounts[previousReaction] =
              (_controller.reactionCounts[previousReaction] ?? 1) - 1;
          if (_controller.reactionCounts[previousReaction]! <= 0) {
            _controller.reactionCounts.remove(previousReaction);
          }
        }
        _controller.reactionCounts[emoji] =
            (_controller.reactionCounts[emoji] ?? 0) + 1;
        _controller.myReaction.value = nextReaction;
      }
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('react error: $e');
    }
  }

  Future<void> like(String storyID) async {
    final uid = _controller._currentUid;
    if (uid.isEmpty) return;
    final next = await _controller._storyRepository.toggleStoryLike(
      storyID,
      currentUid: uid,
    );
    if (next) {
      _controller.isLikedMe.value = true;
      if (_controller.likeCount.value >= 0) {
        _controller.likeCount.value++;
      }
    } else {
      _controller.isLikedMe.value = false;
      if (_controller.likeCount.value >= 0) {
        _controller.likeCount.value--;
      }
    }
  }

  Future<void> setSeen(String storyID) async {
    final uid = _controller._currentUid;
    if (uid.isEmpty) return;
    await _controller._storyRepository.setStorySeen(
      storyID,
      currentUid: uid,
    );
  }
}
