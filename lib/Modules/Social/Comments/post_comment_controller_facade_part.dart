part of 'post_comment_controller_library.dart';

String? _postCommentControllerActiveTag;

PostCommentController ensurePostCommentController({
  required String postID,
  required String userID,
  required String collection,
  Function(bool increment)? onCommentCountChange,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindPostCommentController(tag: tag);
  if (existing != null) {
    return existing;
  }

  final controller = PostCommentController(
    postID: postID,
    userID: userID,
    collection: collection,
    onCommentCountChange: onCommentCountChange,
  );
  final normalizedTag = tag?.trim();
  if (normalizedTag != null && normalizedTag.isNotEmpty) {
    controller.controllerTag = normalizedTag;
  }

  final registered = Get.put(
    controller,
    tag: tag,
    permanent: permanent,
  );

  if (normalizedTag != null && normalizedTag.isNotEmpty) {
    _postCommentControllerActiveTag = normalizedTag;
  }

  return registered;
}

PostCommentController? maybeFindPostCommentController({String? tag}) {
  final normalizedTag = tag?.trim();
  if (normalizedTag != null && normalizedTag.isNotEmpty) {
    return Get.isRegistered<PostCommentController>(tag: normalizedTag)
        ? Get.find<PostCommentController>(tag: normalizedTag)
        : null;
  }

  if (Get.isRegistered<PostCommentController>()) {
    return Get.find<PostCommentController>();
  }

  final activeTag = _postCommentControllerActiveTag?.trim() ?? '';
  if (activeTag.isEmpty) {
    return null;
  }

  return Get.isRegistered<PostCommentController>(tag: activeTag)
      ? Get.find<PostCommentController>(tag: activeTag)
      : null;
}

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
