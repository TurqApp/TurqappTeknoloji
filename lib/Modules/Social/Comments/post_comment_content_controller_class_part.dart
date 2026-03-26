part of 'post_comment_content_controller.dart';

class PostCommentContentController extends GetxController {
  static PostCommentContentController ensure({
    required PostCommentModel model,
    required String postID,
    required String commentControllerTag,
    String? tag,
    bool permanent = false,
  }) =>
      _ensurePostCommentContentController(
        model: model,
        postID: postID,
        commentControllerTag: commentControllerTag,
        tag: tag,
        permanent: permanent,
      );

  static PostCommentContentController? maybeFind({String? tag}) =>
      _maybeFindPostCommentContentController(tag: tag);

  PostCommentContentController({
    required PostCommentModel model,
    required String postID,
    required String commentControllerTag,
  }) : _state = _PostCommentContentControllerState(
          model: model,
          postID: postID,
          commentControllerTag: commentControllerTag,
        );

  final _PostCommentContentControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handlePostCommentContentInit(this);
  }

  @override
  void onClose() {
    _handlePostCommentContentClose(this);
    super.onClose();
  }
}
