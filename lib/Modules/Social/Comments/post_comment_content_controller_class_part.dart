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
    required this.model,
    required this.postID,
    required this.commentControllerTag,
  });

  final PostCommentModel model;
  final String postID;
  final String commentControllerTag;
  final _state = _PostCommentContentControllerState();
  final PostInteractionService _interactionService =
      PostInteractionService.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  @override
  void onInit() {
    super.onInit();
    _handlePostCommentContentInit(this);
  }

  Future<void> toggleLike() =>
      _PostCommentContentControllerActionsPart(this).toggleLike();

  Future<bool> deleteComment() =>
      _PostCommentContentControllerActionsPart(this).deleteComment();

  @override
  void onClose() {
    _handlePostCommentContentClose(this);
    super.onClose();
  }
}
