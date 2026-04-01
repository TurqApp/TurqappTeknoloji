part of 'user_story_content_controller_library.dart';

abstract class _UserStoryContentControllerBase extends GetxController {
  _UserStoryContentControllerBase({
    required String storyID,
    required String nickname,
    required bool isMyStory,
  }) : _state = _UserStoryContentControllerState(storyID, nickname, isMyStory);

  final _UserStoryContentControllerState _state;
}

class UserStoryContentController extends _UserStoryContentControllerBase {
  UserStoryContentController({
    required super.storyID,
    required super.nickname,
    required super.isMyStory,
  }) : super();

  static const List<String> reactionEmojis = [
    '❤️',
    '😂',
    '😮',
    '😢',
    '🔥',
    '👏'
  ];
}
