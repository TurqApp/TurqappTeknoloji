import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Models/story_comment_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryComments/story_comments.dart';
import 'StoryLikes/story_likes.dart';
import 'StorySeens/story_seens.dart';

class UserStoryContentController extends GetxController {
  String storyID;
  String nickname;
  bool isMyStory;
  UserStoryContentController({
    required this.storyID,
    required this.nickname,
    required this.isMyStory,
  });
  List<StoryCommentModel> comments = <StoryCommentModel>[].obs;
  var likeCount = 0.obs;
  var isLikedMe = false.obs;
  final StoryRepository _storyRepository = StoryRepository.ensure();

  // Reaction emoji support
  static const List<String> reactionEmojis = [
    '❤️',
    '😂',
    '😮',
    '😢',
    '🔥',
    '👏'
  ];
  final RxMap<String, int> reactionCounts = <String, int>{}.obs;
  final RxString myReaction = ''.obs;

  Future<void> getLikes(String storyID) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final snapshot = await _storyRepository.fetchStoryEngagement(
      storyID,
      currentUid: uid,
    );
    likeCount.value = snapshot.likeCount;
    isLikedMe.value = snapshot.isLiked;
    reactionCounts.assignAll(snapshot.reactionCounts);
    myReaction.value = snapshot.myReaction;
  }

  Future<void> showPostCommentsBottomSheet(
      String docID, String nickname, bool isMyStory,
      {void Function(bool)? onClosed}) async {
    Get.bottomSheet(
      SizedBox(
        height: Get.height * 0.55,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: StoryComments(
              storyID: storyID, nickname: nickname, isMyStory: isMyStory),
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
    ).then((_) {
      if (onClosed != null) {
        onClosed(true); // Sheet kapandı, callback tetikleniyor
      }
    });
  }

  Future<void> showLikesBottomSheet(String docID,
      {void Function(bool)? onClosed}) async {
    Get.bottomSheet(
      SizedBox(
        height: Get.height * 0.55,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: StoryLikes(storyID: storyID),
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
    ).then((_) {
      if (onClosed != null) {
        onClosed(true);
      }
    });
  }

  Future<void> showSeensBottomSheet(String docID,
      {void Function(bool)? onClosed}) async {
    Get.bottomSheet(
      SizedBox(
        height: Get.height * 0.55,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: StorySeens(storyID: storyID),
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
    ).then((_) {
      if (onClosed != null) {
        onClosed(true);
      }
    });
  }

  Future<void> getReactions(String storyID) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final snapshot = await _storyRepository.fetchStoryEngagement(
        storyID,
        currentUid: uid,
      );
      reactionCounts.assignAll(snapshot.reactionCounts);
      myReaction.value = snapshot.myReaction;
    } catch (e) {
      print("getReactions error: $e");
    }
  }

  Future<void> react(String storyID, String emoji) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;

      final previousReaction = myReaction.value;
      final nextReaction = await _storyRepository.toggleStoryReaction(
        storyID,
        currentUid: uid,
        emoji: emoji,
        currentReaction: previousReaction,
      );

      if (previousReaction == emoji) {
        reactionCounts[emoji] = (reactionCounts[emoji] ?? 1) - 1;
        if (reactionCounts[emoji]! <= 0) reactionCounts.remove(emoji);
        myReaction.value = '';
      } else {
        if (previousReaction.isNotEmpty) {
          reactionCounts[previousReaction] =
              (reactionCounts[previousReaction] ?? 1) - 1;
          if (reactionCounts[previousReaction]! <= 0) {
            reactionCounts.remove(previousReaction);
          }
        }
        reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
        myReaction.value = nextReaction;
      }
      HapticFeedback.lightImpact();
    } catch (e) {
      print("react error: $e");
    }
  }

  Future<void> like(String storyID) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final next = await _storyRepository.toggleStoryLike(
      storyID,
      currentUid: uid,
    );
    if (next) {
      isLikedMe.value = true;
      if (likeCount.value >= 0) {
        likeCount.value++;
      }
    } else {
      isLikedMe.value = false;
      if (likeCount.value >= 0) {
        likeCount.value--;
      }
    }
  }

  Future<void> setSeen(String storyID) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    await _storyRepository.setStorySeen(
      storyID,
      currentUid: uid,
    );
  }
}
