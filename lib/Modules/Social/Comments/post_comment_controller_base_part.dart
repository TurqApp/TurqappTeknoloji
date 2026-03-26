part of 'post_comment_controller.dart';

abstract class _PostCommentControllerBase extends GetxController {
  _PostCommentControllerBase({
    required String postID,
    required String userID,
    required String collection,
    Function(bool increment)? onCommentCountChange,
  }) : _state = _PostCommentControllerState(
          postID: postID,
          userID: userID,
          collection: collection,
          onCommentCountChange: onCommentCountChange,
        );

  final _PostCommentControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handlePostCommentControllerOnInit(this as PostCommentController);
  }

  @override
  void onClose() {
    _handlePostCommentControllerOnClose(this as PostCommentController);
    super.onClose();
  }
}
