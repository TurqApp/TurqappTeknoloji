part of 'chat_controller.dart';

extension ChatControllerSupportPart on ChatController {
  NetworkAwarenessService? get _network => NetworkAwarenessService.maybeFind();

  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;

  Duration get _serverSyncGap {
    if (_isOffline) return const Duration(days: 1);
    return _isOnWiFi
        ? const Duration(seconds: 12)
        : const Duration(seconds: 30);
  }

  Future<void> _clearConversationUnread() =>
      _ChatControllerConversationX(this)._clearConversationUnread();

  void _recordMediaAction(String value) => _performRecordMediaAction(value);

  void _clearMediaFailure() => _performClearMediaFailure();

  void _recordMediaFailure(String code, {String detail = ''}) =>
      _performRecordMediaFailure(code, detail: detail);

  void _syncUnreadIndicatorsLocal() =>
      _ChatControllerConversationX(this)._syncUnreadIndicatorsLocal();

  Future<void> _markConversationOpenedNow() =>
      _ChatControllerConversationX(this)._markConversationOpenedNow();

  Future<void> _markConversationOpenedAt(int timestampMs) =>
      _ChatControllerConversationX(this)._markConversationOpenedAt(
        timestampMs,
      );

  void getUserData() => _ChatControllerConversationX(this).getUserData();

  void scrollToBottom() => _ChatControllerConversationX(this).scrollToBottom();

  void _onTypingChanged() =>
      _ChatControllerConversationX(this)._onTypingChanged();

  void _clearTyping() => _ChatControllerConversationX(this)._clearTyping();

  void _listenTypingState() =>
      _ChatControllerConversationX(this)._listenTypingState();

  Future<void> getData() => _ChatControllerConversationX(this).getData();

  Future<void> loadChatBackgroundPreference() =>
      _ChatControllerConversationX(this).loadChatBackgroundPreference();

  Future<void> setChatBackgroundPreference(int index) =>
      _ChatControllerConversationX(this).setChatBackgroundPreference(index);

  Future<void> _syncMessages({required bool forceServer}) =>
      _ChatControllerConversationSyncX(this)
          ._syncMessages(forceServer: forceServer);

  Future<void> loadOlderMessages() =>
      _ChatControllerConversationSyncX(this).loadOlderMessages();

  Future<void> jumpToMessageByRawId(String rawId) =>
      _ChatControllerConversationSyncX(this).jumpToMessageByRawId(rawId);

  Future<void> archiveCurrentChat() => _performArchiveCurrentChat();
}
