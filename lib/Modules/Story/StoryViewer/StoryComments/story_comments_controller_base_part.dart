part of 'story_comments_controller.dart';

abstract class _StoryCommentsControllerBase extends GetxController {
  _StoryCommentsControllerBase({
    required String nickname,
    required String storyID,
  }) : _state = _StoryCommentsControllerState(
          nickname: nickname,
          storyID: storyID,
        );

  final _StoryCommentsControllerState _state;

  @override
  void onClose() {
    _handleStoryCommentsClose(this as StoryCommentsController);
    super.onClose();
  }
}
