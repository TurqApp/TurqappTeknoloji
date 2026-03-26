part of 'user_story_content_controller.dart';

class UserStoryContentController extends GetxController {
  final _UserStoryContentControllerState _state;

  UserStoryContentController({
    required String storyID,
    required String nickname,
    required bool isMyStory,
  }) : _state = _UserStoryContentControllerState(
          storyID: storyID,
          nickname: nickname,
          isMyStory: isMyStory,
        );

  static const List<String> reactionEmojis = [
    '❤️',
    '😂',
    '😮',
    '😢',
    '🔥',
    '👏'
  ];
}
