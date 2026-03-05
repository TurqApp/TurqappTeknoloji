import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../Core/blocked_texts.dart';
import '../../../Core/functions.dart';
import '../../../Models/post_interactions_models_new.dart';
import '../../../Services/firebase_my_store.dart';
import '../../../Services/post_interaction_service.dart';

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
  final RxSet<String> pendingCommentIds = <String>{}.obs;
  final RxString postUserNickname = ''.obs;
  final RxString replyingToCommentId = ''.obs;
  final RxString replyingToNickname = ''.obs;
  final Map<String, PostCommentModel> _pendingLocalComments = {};

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
      final serverComments = comments.where((c) => !c.deleted).toList();
      final serverIds = serverComments.map((c) => c.docID).toSet();

      // Sunucuya düşen pending yorumları local pending havuzundan çıkar.
      final resolvedPending =
          pendingCommentIds.where(serverIds.contains).toList();
      for (final id in resolvedPending) {
        pendingCommentIds.remove(id);
        _pendingLocalComments.remove(id);
      }

      final pendingOnly = _pendingLocalComments.values
          .where((c) => !serverIds.contains(c.docID))
          .toList();

      final merged = <PostCommentModel>[
        ...pendingOnly,
        ...serverComments,
      ]..sort((a, b) => (b.timeStamp).compareTo(a.timeStamp));

      list.value = merged;
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

    final targetCommentId = replyingToCommentId.value.trim();
    String? commentId;
    if (targetCommentId.isNotEmpty) {
      commentId = await _interactionService.addSubComment(
        postID,
        targetCommentId,
        trimmed,
      );
    } else {
      commentId = await _interactionService.addComment(postID, trimmed);
      if (commentId != null && commentId.startsWith('offline_')) {
        final currentUid = userStore.userID.value;
        if (currentUid.isNotEmpty) {
          final local = PostCommentModel(
            likes: [],
            text: trimmed,
            imgs: const [],
            videos: const [],
            timeStamp: DateTime.now().millisecondsSinceEpoch,
            userID: currentUid,
            docID: commentId,
            edited: false,
            editTimestamp: 0,
            deleted: false,
            deletedTimeStamp: 0,
            hasReplies: false,
            repliesCount: 0,
          );
          pendingCommentIds.add(commentId);
          _pendingLocalComments[commentId] = local;

          // Stream güncellemesi gelmeden kullanıcı yorumu görsün.
          final merged = <PostCommentModel>[
            local,
            ...list.where((c) => c.docID != commentId),
          ]..sort((a, b) => (b.timeStamp).compareTo(a.timeStamp));
          list.value = merged;
        }
      }
    }

    if (commentId != null && onCommentCountChange != null) {
      onCommentCountChange!(true);
    }

    clearReplyTarget();
    onComplete?.call();
  }

  bool isPendingComment(String commentId) =>
      pendingCommentIds.contains(commentId);

  Future<bool> deleteComment(String commentId) async {
    final success = await _interactionService.deleteComment(postID, commentId);
    if (success && onCommentCountChange != null) {
      onCommentCountChange!(false);
    }
    return success;
  }

  Future<void> toggleCommentLike(String commentId) async {
    await _interactionService.toggleCommentLike(postID, commentId);
  }

  void setReplyTarget({required String commentId, required String nickname}) {
    replyingToCommentId.value = commentId;
    replyingToNickname.value = nickname.trim();
  }

  void clearReplyTarget() {
    replyingToCommentId.value = '';
    replyingToNickname.value = '';
  }

  @override
  void onClose() {
    _commentSub?.cancel();
    super.onClose();
  }
}
