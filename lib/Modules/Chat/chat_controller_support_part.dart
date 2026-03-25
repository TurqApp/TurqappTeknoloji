part of 'chat_controller.dart';

String? _activeChatTag;
final ConversationRepository _conversationRepository =
    ConversationRepository.ensure();
const int _initialPageSize = 60;
const int _olderPageSize = 40;
const int _syncHeadSize = 40;
const int _typingHeartbeatIntervalMs = 1500;
const int _localChatWindowLimit = 180;
final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

ChatController? _resolveRegisteredChatController({String? tag}) {
  final resolvedTag = (tag ?? _activeChatTag)?.trim();
  final normalizedTag = resolvedTag?.isEmpty == true ? null : resolvedTag;
  final isRegistered = Get.isRegistered<ChatController>(tag: normalizedTag);
  if (!isRegistered) return null;
  return Get.find<ChatController>(tag: normalizedTag);
}

ChatController _ensureChatController({
  required String chatID,
  required String userID,
  String? tag,
  bool permanent = false,
}) {
  final existing = _resolveRegisteredChatController(tag: tag);
  if (existing != null) {
    _activeChatTag = tag ?? chatID;
    return existing;
  }
  final created = Get.put(
    ChatController(chatID: chatID, userID: userID),
    tag: tag,
    permanent: permanent,
  );
  _activeChatTag = tag ?? chatID;
  return created;
}

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
