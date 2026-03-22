part of 'chat_controller.dart';

extension ChatControllerComposerPart on ChatController {
  void seedSelectedGifForTesting(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    selectedGifUrl.value = trimmed;
    focus.unfocus();
  }

  Future<void> sendSyntheticAudioForTesting({
    required String audioUrl,
    required int audioDurationMs,
  }) async {
    final trimmed = audioUrl.trim();
    if (trimmed.isEmpty) return;
    await sendMessage(
      audioUrl: trimmed,
      audioDurationMs: audioDurationMs,
    );
  }

  Future<void> sendSyntheticImagesForTesting(List<String> imageUrls) async {
    final sanitized = imageUrls
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (sanitized.isEmpty) return;
    await sendMessage(imageUrls: sanitized);
  }

  Future<void> sendSyntheticVideoForTesting({
    required String videoUrl,
    String thumbnailUrl = '',
  }) async {
    final trimmedVideo = videoUrl.trim();
    if (trimmedVideo.isEmpty) return;
    final trimmedThumbnail = thumbnailUrl.trim();
    await sendMessage(
      videoUrl: trimmedVideo,
      videoThumbnail: trimmedThumbnail.isEmpty ? null : trimmedThumbnail,
    );
  }

  void startReply(MessageModel model) {
    replyingTo.value = model;
    editingMessage.value = null;
    focus.requestFocus();
  }

  void startEdit(MessageModel model) {
    if (model.userID != CurrentUserService.instance.effectiveUserId) return;
    if (model.metin.trim().isEmpty) return;
    editingMessage.value = model;
    replyingTo.value = null;
    textEditingController.text = model.metin;
    textMesage.value = model.metin;
    focus.requestFocus();
  }

  void clearComposerAction() {
    replyingTo.value = null;
    editingMessage.value = null;
    selectedGifUrl.value = '';
  }

  Future<void> pickGif(BuildContext context) async {
    final url = await GiphyPickerService.pickGifUrl(
      context,
      randomId: 'turqapp_chat_$chatID',
    );
    if (url != null && url.trim().isNotEmpty) {
      selectedGifUrl.value = url.trim();
      focus.unfocus();
    }
  }

  void startSelectionMode([String? rawId]) {
    isSelectionMode.value = true;
    if (rawId != null && rawId.isNotEmpty) {
      toggleSelection(rawId);
    }
  }

  void stopSelectionMode() {
    isSelectionMode.value = false;
    selectedMessageIds.clear();
  }

  void toggleSelection(String rawId) {
    if (rawId.isEmpty) return;
    final next = Set<String>.from(selectedMessageIds);
    if (next.contains(rawId)) {
      next.remove(rawId);
    } else {
      next.add(rawId);
    }
    selectedMessageIds
      ..clear()
      ..addAll(next);
    if (selectedMessageIds.isEmpty) {
      isSelectionMode.value = false;
    } else {
      isSelectionMode.value = true;
    }
  }

  void toggleStarredFilter() {
    showStarredOnly.value = !showStarredOnly.value;
  }

  List<MessageModel> get filteredMessages {
    if (!showStarredOnly.value) return messages;
    return messages.where((m) => m.isStarred).toList();
  }
}
