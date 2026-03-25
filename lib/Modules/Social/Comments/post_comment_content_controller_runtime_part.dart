part of 'post_comment_content_controller.dart';

extension PostCommentContentControllerRuntimePart
    on PostCommentContentController {
  Future<void> _loadUserProfile(String userID) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary != null) {
        nickname.value = summary.preferredName;
        avatarUrl.value = summary.avatarUrl;
      }
    } catch (_) {}
  }

  void _bindReplies() {
    _replySub?.cancel();
    _replySub = _interactionService
        .listenSubComments(postID, model.docID, limit: 50)
        .listen((items) {
      replies.assignAll(items);
      for (final reply in items) {
        _primeReplyProfile(reply.userID);
      }
    });
  }

  Future<void> _primeReplyProfile(String userID) async {
    final uid = userID.trim();
    if (uid.isEmpty) return;
    if (replyNicknames.containsKey(uid) && replyAvatarUrls.containsKey(uid)) {
      return;
    }
    try {
      final summary = await _userSummaryResolver.resolve(
        uid,
        preferCache: true,
      );
      if (summary == null) return;
      replyNicknames[uid] = summary.preferredName;
      replyAvatarUrls[uid] = summary.avatarUrl;
    } catch (_) {}
  }

  void _applyLocalLikeState({
    required String uid,
    required bool liked,
  }) {
    if (liked) {
      if (!likes.contains(uid)) {
        likes.add(uid);
      }
      if (!model.likes.contains(uid)) {
        model.likes.add(uid);
      }
    } else {
      likes.remove(uid);
      model.likes.remove(uid);
    }
    final parent = PostCommentController.maybeFind(tag: commentControllerTag);
    parent?.syncCommentLikeLocally(
      commentId: model.docID,
      userId: uid,
      liked: liked,
    );
  }

  Future<bool> deleteReply(String replyId) async {
    final trimmed = replyId.trim();
    if (trimmed.isEmpty) return false;
    final ok = await _interactionService.deleteComment(
      postID,
      trimmed,
      isSubComment: true,
      parentCommentId: model.docID,
    );
    if (ok) {
      replies.removeWhere((reply) => reply.docID == trimmed);
    }
    return ok;
  }
}
