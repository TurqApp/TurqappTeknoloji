part of 'chat_controller.dart';

extension ChatControllerRuntimePart on ChatController {
  void _initializeChatRuntime() {
    ChatController._activeTag = chatID;
    getUserData();
    loadChatBackgroundPreference();
    unawaited(getData());
    _clearConversationUnread();
    _syncUnreadIndicatorsLocal();
    unawaited(_markConversationOpenedNow());
    textEditingController.addListener(() {
      textMesage.value = textEditingController.text;
      _onTypingChanged();
    });
    _listenTypingState();
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
        loadOlderMessages();
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
    if (ChatController._activeTag == chatID) {
      ChatController._activeTag = null;
    }
    unawaited(_markConversationOpenedNow());
    _messageSyncTimer?.cancel();
    _messagesSubscription?.cancel();
    _realtimeHeadSignature = '';
    _typingStream?.cancel();
    _typingDebounce?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    textEditingController.dispose();
    scrollController.dispose();
    pageController.dispose();
    focus.dispose();
    _clearTyping();
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
