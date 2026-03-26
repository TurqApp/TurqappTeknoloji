part of 'story_comments_controller.dart';

class StoryCommentsController extends GetxController {
  static String? _activeTag;

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

  Future<void> getData() => _getStoryCommentsData(this);

  Future<void> getLast() => _getLastStoryComment(this);

  Future<void> setComment() => _setStoryComment(this);

  Future<void> pickGif(BuildContext context) => _pickStoryGif(this, context);

  void clearSelectedGif() => _clearStorySelectedGif(this);

  @override
  void onClose() {
    _handleStoryCommentsClose(this);
    super.onClose();
  }
}
