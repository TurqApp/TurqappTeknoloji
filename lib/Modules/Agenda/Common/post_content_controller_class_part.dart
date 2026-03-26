part of 'post_content_controller.dart';

class PostContentController extends _PostContentControllerBase {
  PostContentController({
    required super.model,
    super.enableLegacyCommentSync = false,
    super.scrollFeedToTopOnReshare = false,
  });
}
