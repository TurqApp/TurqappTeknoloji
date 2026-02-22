import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Models/StoryCommentModel.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryComments/StoryComments.dart';
import 'StoryLikes/StoryLikes.dart';
import 'StorySeens/StorySeens.dart';

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

  Future<void> getLikes(String storyID) async {
    FirebaseFirestore.instance
        .collection("Stories")
        .doc(storyID)
        .collection("likes")
        .count()
        .get()
        .then((snap) {
      likeCount.value = snap.count ?? 0;
    });

    FirebaseFirestore.instance
        .collection("Stories")
        .doc(storyID)
        .collection("likes")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) {
      isLikedMe.value = doc.exists;
      print("BEGENILMISSS");
    });
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

  Future<void> like(String storyID) async {
    final docRef = FirebaseFirestore.instance
        .collection("Stories")
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
        .collection("Stories")
        .doc(storyID)
        .collection("Viewers")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({"timeStamp": DateTime.now().millisecondsSinceEpoch});
  }
}
