part of 'user_story_content_controller.dart';

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
