part of 'post_comment_content_controller.dart';

class PostCommentContentController extends GetxController {
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
