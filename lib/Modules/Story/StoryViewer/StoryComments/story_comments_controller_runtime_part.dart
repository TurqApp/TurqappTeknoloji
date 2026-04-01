part of 'story_comments_controller.dart';

String? _storyCommentsActiveTag;

extension StoryCommentsControllerRuntimePart on StoryCommentsController {
  Future<void> _getDataImpl() async {
    if ((controllerTag ?? '').trim().isNotEmpty) {
      _storyCommentsActiveTag = controllerTag;
    }
    list.assignAll(await _storyRepository.fetchStoryComments(storyID));
    totalComment.value = await _storyRepository.fetchStoryCommentCount(storyID);
  }

  Future<void> _getLastImpl() async {
    final last = await _storyRepository.fetchLatestStoryComment(storyID);
    if (last != null) {
      list.insert(0, last);
    }

    totalComment.value++;
  }

  Future<void> _setCommentImpl() async {
    final text = commentTextfield.text.trim();
    final gif = selectedGifUrl.value.trim();
    if (text.isEmpty && gif.isEmpty) {
      return;
    }
    try {
      await _storyRepository.addStoryComment(
        storyID,
        userId: _currentUserId,
        text: text,
        gif: gif,
      );
      lastSuccessfulCommentText.value = text;
      lastSuccessfulCommentGif.value = gif;
      commentTextfield.clear();
      selectedGifUrl.value = '';
      await getLast();
      final context = Get.context;
      if (context != null) {
        closeKeyboard(context);
      }
    } catch (e) {
      debugPrint('setComment error: $e');
    }
  }

  Future<void> _pickGifImpl(BuildContext context) async {
    final url = await GiphyPickerService.pickGifUrl(
      context,
      randomId: 'turqapp_story_comments',
    );
    if (url != null && url.trim().isNotEmpty) {
      selectedGifUrl.value = url.trim();
    }
  }

  void _clearSelectedGifImpl() {
    selectedGifUrl.value = '';
  }

  void _handleClose() {
    if (_storyCommentsActiveTag == controllerTag) {
      _storyCommentsActiveTag = null;
    }
    commentFocus.dispose();
    commentTextfield.dispose();
  }
}

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
