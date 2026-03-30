part of 'chat_listing_controller.dart';

class _ChatListingControllerState {
  final RxList<ChatListingModel> list = <ChatListingModel>[].obs;
  final RxList<ChatListingModel> filteredList = <ChatListingModel>[].obs;
  final RxString selectedTab = "all".obs;
  final TextEditingController search = TextEditingController();
  final RxBool waiting = false.obs;

  Timer? searchDebounce;
  Timer? syncTimer;
  Timer? realtimeRefreshDebounce;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? conversationsSub;
  StreamSubscription<CacheInvalidationEvent>? invalidationSub;
  bool isRefreshing = false;
  bool cacheLoaded = false;
}

extension ChatListingControllerFieldsPart on ChatListingController {
  RxList<ChatListingModel> get list => _state.list;
  RxList<ChatListingModel> get filteredList => _state.filteredList;
  RxString get selectedTab => _state.selectedTab;
  TextEditingController get search => _state.search;
  RxBool get waiting => _state.waiting;

  Timer? get _searchDebounce => _state.searchDebounce;
  set _searchDebounce(Timer? value) => _state.searchDebounce = value;

  Timer? get _syncTimer => _state.syncTimer;
  set _syncTimer(Timer? value) => _state.syncTimer = value;

  Timer? get _realtimeRefreshDebounce => _state.realtimeRefreshDebounce;
  set _realtimeRefreshDebounce(Timer? value) =>
      _state.realtimeRefreshDebounce = value;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      get _conversationsSub => _state.conversationsSub;
  set _conversationsSub(
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? value,
  ) =>
      _state.conversationsSub = value;

  StreamSubscription<CacheInvalidationEvent>? get _invalidationSub =>
      _state.invalidationSub;
  set _invalidationSub(StreamSubscription<CacheInvalidationEvent>? value) =>
      _state.invalidationSub = value;

  bool get _isRefreshing => _state.isRefreshing;
  set _isRefreshing(bool value) => _state.isRefreshing = value;

  bool get _cacheLoaded => _state.cacheLoaded;
  set _cacheLoaded(bool value) => _state.cacheLoaded = value;
}
