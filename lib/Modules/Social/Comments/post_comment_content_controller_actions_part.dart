part of 'post_comment_content_controller.dart';

class _PostCommentContentControllerActionsPart {
  final PostCommentContentController controller;

  const _PostCommentContentControllerActionsPart(this.controller);

  Future<void> toggleLike() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final wasLiked = controller.likes.contains(uid);
    controller._applyLocalLikeState(uid: uid, liked: !wasLiked);
    try {
      await controller._interactionService.toggleCommentLike(
        controller.postID,
        controller.model.docID,
      );
    } catch (e) {
      controller._applyLocalLikeState(uid: uid, liked: wasLiked);
      AppSnackbar('common.error'.tr, 'comments.like_failed'.tr);
    }
  }

  Future<bool> deleteComment() async {
    final parent =
        maybeFindPostCommentController(tag: controller.commentControllerTag);
    if (parent == null) return false;
    return parent.deleteComment(controller.model.docID);
  }
}
