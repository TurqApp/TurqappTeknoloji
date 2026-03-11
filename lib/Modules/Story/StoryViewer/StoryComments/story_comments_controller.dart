import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/giphy_picker_service.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Models/story_comment_model.dart';

class StoryCommentsController extends GetxController {
  RxList<StoryCommentModel> list = <StoryCommentModel>[].obs;
  FocusNode commentFocus = FocusNode();
  TextEditingController commentTextfield = TextEditingController();
  String nickname = "";
  String storyID = "";
  var totalComment = 0.obs;
  final RxString selectedGifUrl = ''.obs;

  StoryCommentsController({required this.nickname, required this.storyID});

  Future<void> getData() async {
    await FirebaseFirestore.instance
        .collection("stories")
        .doc(storyID)
        .collection("Yorumlar")
        .limit(50)
        .get()
        .then((snap) {
      final items = snap.docs
          .map((doc) => StoryCommentModel.fromMap(doc.data(), docID: doc.id))
          .toList();
      list.assignAll(items);
    });

    FirebaseFirestore.instance
        .collection("stories")
        .doc(storyID)
        .collection("Yorumlar")
        .count()
        .get()
        .then((counts) {
      totalComment.value = counts.count ?? 0;
    });
  }

  Future<void> getLast() async {
    await FirebaseFirestore.instance
        .collection("stories")
        .doc(storyID)
        .collection("Yorumlar")
        .limit(1)
        .orderBy("timeStamp", descending: true)
        .get()
        .then((snap) {
      for (var doc in snap.docs) {
        final model = StoryCommentModel.fromMap(doc.data(), docID: doc.id);
        list.insert(0, model);
      }
    });

    totalComment.value++;
  }

  Future<void> setComment() async {
    final text = commentTextfield.text.trim();
    final gif = selectedGifUrl.value.trim();
    if (text.isEmpty && gif.isEmpty) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection("stories")
          .doc(storyID)
          .collection("Yorumlar")
          .add({
        "userID": FirebaseAuth.instance.currentUser!.uid,
        "metin": text,
        "timeStamp": DateTime.now().millisecondsSinceEpoch,
        "gif": gif
      });
      commentTextfield.clear();
      selectedGifUrl.value = '';
      await getLast();
      closeKeyboard(Get.context!);
    } catch (e) {
      print("setComment error: $e");
    }
  }

  Future<void> pickGif(BuildContext context) async {
    final url = await GiphyPickerService.pickGifUrl(
      context,
      randomId: 'turqapp_story_comments',
    );
    if (url != null && url.trim().isNotEmpty) {
      selectedGifUrl.value = url.trim();
    }
  }

  void clearSelectedGif() {
    selectedGifUrl.value = '';
  }
}
