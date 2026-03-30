part of 'chat_listing_controller.dart';

ChatListingController _ensureChatListingController() =>
    _maybeFindChatListingController() ?? Get.put(ChatListingController());

ChatListingController? _maybeFindChatListingController() =>
    Get.isRegistered<ChatListingController>()
        ? Get.find<ChatListingController>()
        : null;

extension ChatListingControllerFacadePart on ChatListingController {
  NetworkAwarenessService? get _network => NetworkAwarenessService.maybeFind();

  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;
  String get _uid => CurrentUserService.instance.effectiveUserId;
  Duration get _syncInterval {
    if (_isOffline) return const Duration(seconds: 25);
    return _isOnWiFi
        ? const Duration(seconds: 12)
        : const Duration(seconds: 18);
  }

  String get _cacheKey {
    final uid = CurrentUserService.instance.effectiveUserId;
    return uid.isEmpty ? '' : 'chat_listing_cache_$uid';
  }
}

void _handleChatListingInit(ChatListingController controller) {
  controller.search.addListener(controller._onSearchChanged);
  controller._restoreCachedList();
  controller.getList(forceServer: false);
  controller.startConversationListener();
  controller._listenCacheInvalidations();
}

void _handleChatListingClose(ChatListingController controller) {
  controller._searchDebounce?.cancel();
  controller._syncTimer?.cancel();
  controller._realtimeRefreshDebounce?.cancel();
  controller._conversationsSub?.cancel();
  controller._invalidationSub?.cancel();
  controller.search.removeListener(controller._onSearchChanged);
  controller.search.dispose();
}
