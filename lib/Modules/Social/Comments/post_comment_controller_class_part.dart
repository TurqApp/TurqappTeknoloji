part of 'post_comment_controller.dart';

class PostCommentController extends _PostCommentControllerBase {
  PostCommentController({
    required super.postID,
    required super.userID,
    required super.collection,
    super.onCommentCountChange,
  });
}
