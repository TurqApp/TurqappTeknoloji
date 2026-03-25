part of 'post_comment_controller.dart';

extension PostCommentControllerActions on PostCommentController {
  Future<void> yorumYap(
    BuildContext context,
    String text, {
    VoidCallback? onComplete,
  }) async {
    final gifUrl = selectedGifUrl.value.trim();
    if (kufurKontrolEt(text)) {
      showAlertDialog(
        context,
        'comments.community_violation_title'.tr,
        'comments.community_violation_body'.tr,
      );
      return;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty && gifUrl.isEmpty) return;

    final targetCommentId = replyingToCommentId.value.trim();
    String? commentId;
    if (targetCommentId.isNotEmpty) {
      commentId = await _interactionService.addSubComment(
        postID,
        targetCommentId,
        trimmed,
        imgs: gifUrl.isEmpty ? null : <String>[gifUrl],
      );
    } else {
      commentId = await _interactionService.addComment(
        postID,
        trimmed,
        imgs: gifUrl.isEmpty ? null : <String>[gifUrl],
      );
      if (commentId != null && commentId.startsWith('offline_')) {
        final currentUid = userService.effectiveUserId;
        if (currentUid.isNotEmpty) {
          final local = PostCommentModel(
            likes: [],
            text: trimmed,
            imgs: gifUrl.isEmpty ? const [] : <String>[gifUrl],
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
    if (commentId != null) {
      lastSuccessfulCommentId.value = commentId;
      lastSuccessfulSendText.value = trimmed;
      lastSuccessfulSendWasReply.value = targetCommentId.isNotEmpty;
    }

    clearReplyTarget();
    clearSelectedGif();
    onComplete?.call();
  }

  bool isPendingComment(String commentId) =>
      pendingCommentIds.contains(commentId);

  Future<bool> deleteComment(String commentId) async {
    final existing =
        list.firstWhereOrNull((comment) => comment.docID == commentId);
    final success = await _interactionService.deleteComment(postID, commentId);
    if (success && onCommentCountChange != null) {
      onCommentCountChange!(false);
    }
    if (success) {
      lastDeletedCommentId.value = commentId;
      lastDeletedCommentText.value = existing?.text.trim() ?? '';
      list.removeWhere((comment) => comment.docID == commentId);
      pendingCommentIds.remove(commentId);
      _pendingLocalComments.remove(commentId);
    }
    return success;
  }

  Future<void> toggleCommentLike(String commentId) async {
    await _interactionService.toggleCommentLike(postID, commentId);
  }

  void syncCommentLikeLocally({
    required String commentId,
    required String userId,
    required bool liked,
  }) {
    final index = list.indexWhere((comment) => comment.docID == commentId);
    if (index < 0) return;
    final comment = list[index];
    final updatedLikes = List<String>.from(comment.likes);
    if (liked) {
      if (!updatedLikes.contains(userId)) {
        updatedLikes.add(userId);
      }
    } else {
      updatedLikes.remove(userId);
    }
    list[index] = PostCommentModel(
      likes: updatedLikes,
      text: comment.text,
      imgs: comment.imgs,
      videos: comment.videos,
      timeStamp: comment.timeStamp,
      userID: comment.userID,
      docID: comment.docID,
      edited: comment.edited,
      editTimestamp: comment.editTimestamp,
      deleted: comment.deleted,
      deletedTimeStamp: comment.deletedTimeStamp,
      hasReplies: comment.hasReplies,
      repliesCount: comment.repliesCount,
    );
    list.refresh();
  }

  void setReplyTarget({required String commentId, required String nickname}) {
    replyingToCommentId.value = commentId;
    replyingToNickname.value = nickname.trim();
  }

  void clearReplyTarget() {
    replyingToCommentId.value = '';
    replyingToNickname.value = '';
  }

  Future<void> pickGif(BuildContext context) async {
    final url = await GiphyPickerService.pickGifUrl(
      context,
      randomId: 'turqapp_post_comments',
    );
    if (url != null && url.trim().isNotEmpty) {
      selectedGifUrl.value = url.trim();
    }
  }

  void clearSelectedGif() {
    selectedGifUrl.value = '';
  }
}
