part of 'post_comment_content_controller.dart';

PostCommentContentController _ensurePostCommentContentController({
  required PostCommentModel model,
  required String postID,
  required String commentControllerTag,
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindPostCommentContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    PostCommentContentController(
      model: model,
      postID: postID,
      commentControllerTag: commentControllerTag,
    ),
    tag: tag,
    permanent: permanent,
  );
}

PostCommentContentController? _maybeFindPostCommentContentController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<PostCommentContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<PostCommentContentController>(tag: tag);
}

void _handlePostCommentContentInit(PostCommentContentController controller) {
  controller.likes.assignAll(controller.model.likes);
  controller._loadUserProfile(controller.model.userID);
  controller._bindReplies();
}

void _handlePostCommentContentClose(PostCommentContentController controller) {
  controller._replySub?.cancel();
}

extension PostCommentContentControllerFacadePart
    on PostCommentContentController {
  Future<void> toggleLike() =>
      _PostCommentContentControllerActionsPart(this).toggleLike();

  Future<bool> deleteComment() =>
      _PostCommentContentControllerActionsPart(this).deleteComment();
}
