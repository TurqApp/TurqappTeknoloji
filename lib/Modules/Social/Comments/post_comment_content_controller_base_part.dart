part of 'post_comment_content_controller.dart';

abstract class _PostCommentContentControllerBase extends GetxController {
  _PostCommentContentControllerBase({
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
    _handlePostCommentContentInit(this as PostCommentContentController);
  }

  @override
  void onClose() {
    _handlePostCommentContentClose(this as PostCommentContentController);
    super.onClose();
  }
}
