import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    FirebaseFirestore.instance
        .collection("stories")
        .doc(storyID)
        .collection("likes")
        .count()
        .get()
        .then((snap) {
      likeCount.value = snap.count ?? 0;
    });

    FirebaseFirestore.instance
        .collection("stories")
        .doc(storyID)
        .collection("likes")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) {
      isLikedMe.value = doc.exists;
    });

    // Reaction'ları da yükle
    getReactions(storyID);
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
      final doc = await FirebaseFirestore.instance
          .collection("stories")
          .doc(storyID)
          .get();
      final data = doc.data();
      if (data != null && data['reactions'] is Map) {
        final reactions = Map<String, dynamic>.from(data['reactions']);
        final uid = FirebaseAuth.instance.currentUser!.uid;
        reactionCounts.clear();
        myReaction.value = '';
        for (final entry in reactions.entries) {
          final users = List<String>.from(entry.value ?? []);
          reactionCounts[entry.key] = users.length;
          if (users.contains(uid)) {
            myReaction.value = entry.key;
          }
        }
      }
    } catch (e) {
      print("getReactions error: $e");
    }
  }

  Future<void> react(String storyID, String emoji) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef =
          FirebaseFirestore.instance.collection("stories").doc(storyID);

      // Eğer aynı emoji'ye tekrar tıklandıysa, kaldır
      if (myReaction.value == emoji) {
        await docRef.update({
          'reactions.$emoji': FieldValue.arrayRemove([uid]),
        });
        reactionCounts[emoji] = (reactionCounts[emoji] ?? 1) - 1;
        if (reactionCounts[emoji]! <= 0) reactionCounts.remove(emoji);
        myReaction.value = '';
      } else {
        // Önceki reaction'ı kaldır
        if (myReaction.value.isNotEmpty) {
          await docRef.update({
            'reactions.${myReaction.value}': FieldValue.arrayRemove([uid]),
          });
          reactionCounts[myReaction.value] =
              (reactionCounts[myReaction.value] ?? 1) - 1;
          if (reactionCounts[myReaction.value]! <= 0) {
            reactionCounts.remove(myReaction.value);
          }
        }
        // Yeni reaction ekle
        await docRef.update({
          'reactions.$emoji': FieldValue.arrayUnion([uid]),
        });
        reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
        myReaction.value = emoji;
      }
      HapticFeedback.lightImpact();
    } catch (e) {
      print("react error: $e");
    }
  }

  Future<void> like(String storyID) async {
    final docRef = FirebaseFirestore.instance
        .collection("stories")
        .doc(storyID)
        .collection("likes")
        .doc(FirebaseAuth.instance.currentUser!.uid);

    final doc = await docRef.get();

    if (doc.exists) {
      // Beğeni varsa, kaldır
      isLikedMe.value = false;
      if (likeCount.value >= 0) {
        likeCount.value--;
      }
      await docRef.delete();
    } else {
      isLikedMe.value = true;
      if (likeCount.value >= 0) {
        likeCount.value++;
      }
      await docRef.set({"timeStamp": DateTime.now().millisecondsSinceEpoch});
    }
  }

  Future<void> setSeen(String storyID) async {
    FirebaseFirestore.instance
        .collection("stories")
        .doc(storyID)
        .collection("Viewers")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({"timeStamp": DateTime.now().millisecondsSinceEpoch});
  }
}
