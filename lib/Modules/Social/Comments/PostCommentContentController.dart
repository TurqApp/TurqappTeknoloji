import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../Models/PostInteractionsModelsNew.dart';
import '../../../Services/PostInteractionService.dart';
import 'PostCommentController.dart';

class PostCommentContentController extends GetxController {
  PostCommentContentController({required this.model, required this.postID});

  final PostCommentModel model;
  final String postID;

  final RxString nickname = ''.obs;
  final RxString pfImage = ''.obs;
  final RxList<String> likes = <String>[].obs;
  final PostInteractionService _interactionService =
      Get.put(PostInteractionService());

  @override
  void onInit() {
    super.onInit();
    likes.assignAll(model.likes);
    _loadUserProfile(model.userID);
  }

  Future<void> _loadUserProfile(String userID) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();
      if (doc.exists) {
        nickname.value = doc.get('nickname') ?? '';
        pfImage.value = doc.get('pfImage') ?? '';
      }
    } catch (_) {}
  }

  Future<void> toggleLike() async {
    await _interactionService.toggleCommentLike(postID, model.docID);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (likes.contains(uid)) {
      likes.remove(uid);
    } else {
      likes.add(uid);
    }
  }

  Future<void> deleteComment() async {
    await Get.find<PostCommentController>(tag: postID)
        .deleteComment(model.docID);
  }
}
