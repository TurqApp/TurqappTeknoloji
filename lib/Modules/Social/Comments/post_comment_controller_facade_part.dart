part of 'post_comment_controller_library.dart';

String? _postCommentControllerActiveTag;

PostCommentController ensurePostCommentController({
  required String postID,
  required String userID,
  required String collection,
  Function(bool increment)? onCommentCountChange,
  String? tag,
  bool permanent = false,
}) =>
    maybeFindPostCommentController(tag: tag) ??
    Get.put(
      PostCommentController(
        postID: postID,
        userID: userID,
        collection: collection,
        onCommentCountChange: onCommentCountChange,
      ),
      tag: tag,
      permanent: permanent,
    );

PostCommentController? maybeFindPostCommentController({String? tag}) =>
    Get.isRegistered<PostCommentController>(tag: tag)
        ? Get.find<PostCommentController>(tag: tag)
        : null;

void _handlePostCommentControllerOnInit(PostCommentController controller) {
  if ((controller.controllerTag ?? '').trim().isNotEmpty) {
    _postCommentControllerActiveTag = controller.controllerTag;
  }
  _handlePostCommentControllerInit(controller);
}

void _handlePostCommentControllerOnClose(PostCommentController controller) {
  if (_postCommentControllerActiveTag == controller.controllerTag) {
    _postCommentControllerActiveTag = null;
  }
  _handlePostCommentControllerClose(controller);
}
