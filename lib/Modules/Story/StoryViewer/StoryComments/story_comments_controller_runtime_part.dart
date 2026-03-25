part of 'story_comments_controller.dart';

extension StoryCommentsControllerRuntimePart on StoryCommentsController {
  Future<void> _getDataImpl() async {
    if ((controllerTag ?? '').trim().isNotEmpty) {
      StoryCommentsController._activeTag = controllerTag;
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
    if (StoryCommentsController._activeTag == controllerTag) {
      StoryCommentsController._activeTag = null;
    }
    commentFocus.dispose();
    commentTextfield.dispose();
  }
}
