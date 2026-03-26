part of 'story_comments_controller.dart';

String? _storyCommentsActiveTag;

StoryCommentsController ensureStoryCommentsController({
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

StoryCommentsController? maybeFindStoryCommentsController({String? tag}) =>
    _maybeFindStoryCommentsController(tag: tag);

StoryCommentsController _ensureStoryCommentsController({
  required String nickname,
  required String storyID,
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindStoryCommentsController(tag: tag);
  if (existing != null) {
    _storyCommentsActiveTag = tag;
    return existing;
  }
  final created = Get.put(
    StoryCommentsController(
      nickname: nickname,
      storyID: storyID,
    ),
    tag: tag,
    permanent: permanent,
  );
  created.controllerTag = tag;
  _storyCommentsActiveTag = tag;
  return created;
}

StoryCommentsController? _maybeFindStoryCommentsController({String? tag}) {
  final resolvedTag = (tag ?? _storyCommentsActiveTag)?.trim();
  final effectiveTag = resolvedTag?.isEmpty == true ? null : resolvedTag;
  final isRegistered = Get.isRegistered<StoryCommentsController>(
    tag: effectiveTag,
  );
  if (!isRegistered) return null;
  return Get.find<StoryCommentsController>(tag: effectiveTag);
}

String _storyCommentsCurrentUserId() =>
    CurrentUserService.instance.effectiveUserId;

Future<void> _getStoryCommentsData(StoryCommentsController controller) =>
    controller._getDataImpl();

Future<void> _getLastStoryComment(StoryCommentsController controller) =>
    controller._getLastImpl();

Future<void> _setStoryComment(StoryCommentsController controller) =>
    controller._setCommentImpl();

Future<void> _pickStoryGif(
  StoryCommentsController controller,
  BuildContext context,
) =>
    controller._pickGifImpl(context);

void _clearStorySelectedGif(StoryCommentsController controller) =>
    controller._clearSelectedGifImpl();

void _handleStoryCommentsClose(StoryCommentsController controller) =>
    controller._handleClose();

extension StoryCommentsControllerFacadePart on StoryCommentsController {
  Future<void> getData() => _getStoryCommentsData(this);

  Future<void> getLast() => _getLastStoryComment(this);

  Future<void> setComment() => _setStoryComment(this);

  Future<void> pickGif(BuildContext context) => _pickStoryGif(this, context);

  void clearSelectedGif() => _clearStorySelectedGif(this);
}
