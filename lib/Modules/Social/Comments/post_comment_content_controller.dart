import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../Models/post_interactions_models_new.dart';
import '../../../Services/post_interaction_service.dart';
import 'post_comment_controller.dart';

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

  Future<bool> deleteComment() async {
    return await Get.find<PostCommentController>(tag: postID)
        .deleteComment(model.docID);
  }
}
