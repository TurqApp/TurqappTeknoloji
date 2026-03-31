part of 'unread_messages_controller_library.dart';

class _UnreadMessagesControllerState {
  final RxInt totalUnreadCount = 0.obs;
  Timer? syncTimer;
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      liveConversationSubs =
      <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
  bool listenersStarted = false;
  String? activeUid;
  final Map<String, int> conversationUnreadByUser = {};
  final Map<String, ChatListingModel> cachedListingsByChatId =
      <String, ChatListingModel>{};
  final Map<String, int> localReadCutoffByChatId = {};
  final Map<String, int> persistedReadCutoffByChatId = {};
  bool readStateReady = false;
  DateTime? lastServerSyncAt;
  bool isSyncing = false;
  final ConversationRepository conversationRepository =
      ConversationRepository.ensure();
}

extension UnreadMessagesControllerFieldsPart on UnreadMessagesController {
  RxInt get totalUnreadCount => _state.totalUnreadCount;
  Timer? get _syncTimer => _state.syncTimer;
  set _syncTimer(Timer? value) => _state.syncTimer = value;
  Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      get _liveConversationSubs => _state.liveConversationSubs;
  bool get _listenersStarted => _state.listenersStarted;
  set _listenersStarted(bool value) => _state.listenersStarted = value;
  String? get _activeUid => _state.activeUid;
  set _activeUid(String? value) => _state.activeUid = value;
  Map<String, int> get _conversationUnreadByUser =>
      _state.conversationUnreadByUser;
  Map<String, ChatListingModel> get _cachedListingsByChatId =>
      _state.cachedListingsByChatId;
  Map<String, int> get _localReadCutoffByChatId =>
      _state.localReadCutoffByChatId;
  Map<String, int> get _persistedReadCutoffByChatId =>
      _state.persistedReadCutoffByChatId;
  bool get _readStateReady => _state.readStateReady;
  set _readStateReady(bool value) => _state.readStateReady = value;
  DateTime? get _lastServerSyncAt => _state.lastServerSyncAt;
  set _lastServerSyncAt(DateTime? value) => _state.lastServerSyncAt = value;
  bool get _isSyncing => _state.isSyncing;
  set _isSyncing(bool value) => _state.isSyncing = value;
  ConversationRepository get _conversationRepository =>
      _state.conversationRepository;
  NetworkAwarenessService? get _network => NetworkAwarenessService.maybeFind();
  String get _currentUid => CurrentUserService.instance.effectiveUserId;
  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;
  Duration get _serverSyncGap {
    if (_isOffline) return const Duration(days: 1);
    return _isOnWiFi ? const Duration(seconds: 6) : const Duration(seconds: 12);
  }
}
