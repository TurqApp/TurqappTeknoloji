part of 'post_comment_controller_library.dart';

class PostCommentController extends _PostCommentControllerBase {
  PostCommentController({
    required super.postID,
    required super.userID,
    required super.collection,
    super.onCommentCountChange,
  });
}
