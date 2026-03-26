part of 'user_story_content_controller.dart';

abstract class _UserStoryContentControllerBase extends GetxController {
  _UserStoryContentControllerBase({
    required String storyID,
    required String nickname,
    required bool isMyStory,
  }) : _state = _UserStoryContentControllerState(
          storyID: storyID,
          nickname: nickname,
          isMyStory: isMyStory,
        );

  final _UserStoryContentControllerState _state;
}
