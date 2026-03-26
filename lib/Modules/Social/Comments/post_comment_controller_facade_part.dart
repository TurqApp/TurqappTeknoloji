part of 'post_comment_controller.dart';

PostCommentController _ensurePostCommentControllerFacade({
  required String postID,
  required String userID,
  required String collection,
  Function(bool increment)? onCommentCountChange,
  String? tag,
  bool permanent = false,
}) =>
    _maybeFindPostCommentControllerFacade(tag: tag) ??
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

PostCommentController? _maybeFindPostCommentControllerFacade({String? tag}) =>
    Get.isRegistered<PostCommentController>(tag: tag)
        ? Get.find<PostCommentController>(tag: tag)
        : null;

void _handlePostCommentControllerOnInit(PostCommentController controller) {
  if ((controller.controllerTag ?? '').trim().isNotEmpty) {
    PostCommentController._activeTag = controller.controllerTag;
  }
  _handlePostCommentControllerInit(controller);
}

void _handlePostCommentControllerOnClose(PostCommentController controller) {
  if (PostCommentController._activeTag == controller.controllerTag) {
    PostCommentController._activeTag = null;
  }
  _handlePostCommentControllerClose(controller);
}
