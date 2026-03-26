part of 'post_content_controller.dart';

abstract class _PostContentControllerBase extends GetxController {
  _PostContentControllerBase({
    required PostsModel model,
    required bool enableLegacyCommentSync,
    required bool scrollFeedToTopOnReshare,
  }) : _shellState = _PostContentShellState(
          model: model,
          enableLegacyCommentSync: enableLegacyCommentSync,
          scrollFeedToTopOnReshare: scrollFeedToTopOnReshare,
        );

  final _PostContentShellState _shellState;
}
