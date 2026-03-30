part of 'chat_controller.dart';

extension ChatControllerRuntimePart on ChatController {
  void _initializeChatRuntime() {
    _activeChatTag = chatID;
    ChatControllerSupportPart(this).getUserData();
    unawaited(ChatControllerSupportPart(this).loadChatBackgroundPreference());
    unawaited(ChatControllerSupportPart(this).getData());
    unawaited(ChatControllerSupportPart(this)._clearConversationUnread());
    ChatControllerSupportPart(this)._syncUnreadIndicatorsLocal();
    unawaited(ChatControllerSupportPart(this)._markConversationOpenedNow());
    ChatControllerSupportPart(this)._bindCacheInvalidationListeners();
    textEditingController.addListener(() {
      textMesage.value = textEditingController.text;
      ChatControllerSupportPart(this)._onTypingChanged();
    });
    ChatControllerSupportPart(this)._listenTypingState();
    scrollController.addListener(() {
      final offset = scrollController.offset;
      final visible = offset > 500;
      showScrollDownButton.value = visible;
      if (!visible) {
        scrollDownOpacity.value = 0.0;
      } else {
        final strength = ((offset - 500) / 900).clamp(0.0, 1.0);
        scrollDownOpacity.value = (0.45 + (strength * 0.55)).clamp(0.45, 1.0);
      }
      if (scrollController.hasClients &&
          scrollController.position.maxScrollExtent > 0 &&
          offset > (scrollController.position.maxScrollExtent - 280)) {
        unawaited(ChatControllerSupportPart(this).loadOlderMessages());
      }
    });
  }

  void _performRecordMediaAction(String value) {
    lastMediaAction.value = value.trim();
  }

  void _performClearMediaFailure() {
    lastMediaFailureCode.value = '';
    lastMediaFailureDetail.value = '';
  }

  void _performRecordMediaFailure(String code, {String detail = ''}) {
    lastMediaFailureCode.value = code.trim();
    lastMediaFailureDetail.value = detail.trim();
  }

  void _disposeChatRuntimeResources() {
    if (_activeChatTag == chatID) {
      _activeChatTag = null;
    }
    unawaited(ChatControllerSupportPart(this)._markConversationOpenedNow());
    _messageSyncTimer?.cancel();
    _messagesSubscription?.cancel();
    _realtimeHeadSignature = '';
    _invalidationSubscription?.cancel();
    _typingStream?.cancel();
    _typingDebounce?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    textEditingController.dispose();
    scrollController.dispose();
    pageController.dispose();
    focus.dispose();
    ChatControllerSupportPart(this)._clearTyping();
  }

  Future<void> _performArchiveCurrentChat() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final convDoc = await _conversationRepository.getConversation(
        chatID,
        preferCache: true,
        cacheOnly: false,
      );
      if (convDoc != null) {
        await _conversationRepository.setArchived(
          currentUid: uid,
          otherUserId: userID,
          chatId: chatID,
          archived: true,
        );
      }
    } catch (_) {}
  }
}
