import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../Core/BlockedTexts.dart';
import '../../../Core/Functions.dart';
import '../../../Models/PostInteractionsModelsNew.dart';
import '../../../Services/FirebaseMyStore.dart';
import '../../../Services/PostInteractionService.dart';

class PostCommentController extends GetxController {
  PostCommentController({
    required this.postID,
    required this.userID,
    required this.collection,
    this.onCommentCountChange,
  });

  final String postID;
  final String collection;
  final String userID;
  final Function(bool increment)? onCommentCountChange;

  final FirebaseMyStore userStore = Get.find<FirebaseMyStore>();
  final PostInteractionService _interactionService =
      Get.put(PostInteractionService());

  final RxList<PostCommentModel> list = <PostCommentModel>[].obs;
  final RxString postUserNickname = ''.obs;

  StreamSubscription<List<PostCommentModel>>? _commentSub;

  @override
  void onInit() {
    super.onInit();
    _bindComments();
    _loadPostOwnerNickname();
  }

  void _bindComments() {
    _commentSub?.cancel();
    _commentSub = _interactionService
        .listenComments(postID, limit: 100)
        .listen((comments) {
      list.value = comments.where((c) => !c.deleted).toList();
    });
  }

  Future<void> _loadPostOwnerNickname() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();
      if (doc.exists) {
        postUserNickname.value = doc.get('nickname') ?? '';
      }
    } catch (e) {
      postUserNickname.value = '';
    }
  }

  Future<void> yorumYap(BuildContext context, String text,
      {VoidCallback? onComplete}) async {
    if (kufurKontrolEt(text)) {
      showAlertDialog(
        context,
        'Topluluk Kurallarına Aykırı',
        'Kullandığınız dil, topluluk kurallarımıza uymamaktadır. Lütfen saygılı bir dil kullanınız.',
      );
      return;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final commentId = await _interactionService.addComment(postID, trimmed);

    if (commentId != null && onCommentCountChange != null) {
      onCommentCountChange!(true);
    }

    onComplete?.call();
  }

  Future<void> deleteComment(String commentId) async {
    final success = await _interactionService.deleteComment(postID, commentId);
    if (success && onCommentCountChange != null) {
      onCommentCountChange!(false);
    }
  }

  Future<void> toggleCommentLike(String commentId) async {
    await _interactionService.toggleCommentLike(postID, commentId);
  }

  @override
  void onClose() {
    _commentSub?.cancel();
    super.onClose();
  }
}
