part of 'user_story_content_controller.dart';

class UserStoryContentController extends GetxController {
  static UserStoryContentController ensure({
    required String tag,
    required String storyID,
    required String nickname,
    required bool isMyStory,
    bool permanent = false,
  }) =>
      _ensureUserStoryContentController(
        tag: tag,
        storyID: storyID,
        nickname: nickname,
        isMyStory: isMyStory,
        permanent: permanent,
      );

  static UserStoryContentController? maybeFind({required String tag}) =>
      _maybeFindUserStoryContentController(tag: tag);

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
