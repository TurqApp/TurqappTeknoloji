part of 'story_comments_controller.dart';

class StoryCommentsController extends GetxController {
  final _StoryCommentsControllerState _state;

  StoryCommentsController({
    required String nickname,
    required String storyID,
  }) : _state = _StoryCommentsControllerState(
          nickname: nickname,
          storyID: storyID,
        );

  @override
  void onClose() {
    _handleStoryCommentsClose(this);
    super.onClose();
  }
}
