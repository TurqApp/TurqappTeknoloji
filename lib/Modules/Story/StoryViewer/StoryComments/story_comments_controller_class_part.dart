part of 'story_comments_controller.dart';

class StoryCommentsController extends GetxController {
  static StoryCommentsController ensure({
    required String nickname,
    required String storyID,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureStoryCommentsController(
        nickname: nickname,
        storyID: storyID,
        tag: tag,
        permanent: permanent,
      );

  static StoryCommentsController? maybeFind({String? tag}) =>
      _maybeFindStoryCommentsController(tag: tag);

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
