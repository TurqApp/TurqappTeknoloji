part of 'chat_listing_controller.dart';

extension ChatListingControllerActionsPart on ChatListingController {
  void _onSearchChanged() {
    final query = search.text.trim();

    if (query.isEmpty) {
      _applyTabFilter();
      return;
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () async {
      await _searchInChats(query);
    });
  }

  Future<void> _searchInChats(String query) async {
    final q = normalizeSearchText(query);
    final base = _tabbedList();
    if (q.isEmpty) {
      filteredList.value = base;
      return;
    }

    waiting.value = true;
    try {
      final direct = base.where((item) {
        return normalizeSearchText(item.nickname).contains(q) ||
            normalizeSearchText(item.fullName).contains(q) ||
            normalizeSearchText(item.lastMessage).contains(q);
      }).toList();

      final byUser = <String, ChatListingModel>{};
      for (final item in direct) {
        byUser[item.userID] = item;
      }
      filteredList.value = byUser.values.toList()
        ..sort((a, b) {
          final aTs = int.tryParse(a.timeStamp) ?? 0;
          final bTs = int.tryParse(b.timeStamp) ?? 0;
          return bTs.compareTo(aTs);
        });
    } finally {
      waiting.value = false;
    }
  }

  void updateUnreadLocal({
    required String chatId,
    required int unreadCount,
  }) {
    bool changed = false;
    for (final item in list) {
      if (item.chatID == chatId) {
        if (item.unreadCount != unreadCount) {
          item.unreadCount = unreadCount;
          changed = true;
        }
      }
    }
    if (!changed) return;

    list.refresh();
    if (search.text.trim().isEmpty) {
      _applyTabFilter();
    } else {
      _onSearchChanged();
    }
    _saveCachedList(list.toList());
  }

  void updateConversationPreviewLocal({
    required String chatId,
    required String previewText,
    int timestampMs = 0,
  }) {
    var changed = false;
    for (final item in list) {
      if (item.chatID != chatId) continue;
      if (item.lastMessage != previewText) {
        item.lastMessage = previewText;
        changed = true;
      }
      if (timestampMs > 0 && item.timeStamp != '$timestampMs') {
        item.timeStamp = '$timestampMs';
        changed = true;
      }
    }
    if (!changed) return;

    final sorted = [...list]..sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        final aTs = int.tryParse(a.timeStamp) ?? 0;
        final bTs = int.tryParse(b.timeStamp) ?? 0;
        return bTs.compareTo(aTs);
      });
    list.assignAll(sorted);
    if (search.text.trim().isEmpty) {
      _applyTabFilter();
    } else {
      _onSearchChanged();
    }
    _saveCachedList(list.toList());
  }

  void setTab(String tab) {
    selectedTab.value = tab;
    if (search.text.trim().isEmpty) {
      _applyTabFilter();
    } else {
      _onSearchChanged();
    }
  }

  List<ChatListingModel> _tabbedList() {
    return _applyTabFilterOn(list);
  }

  void _applyTabFilter() {
    filteredList.value = _tabbedList();
  }

  List<ChatListingModel> _applyTabFilterOn(List<ChatListingModel> source) {
    final visible =
        source.where((e) => !e.deleted.contains("__deleted__")).toList();
    if (selectedTab.value == "archive") {
      return visible.where((e) => e.deleted.contains("__archived__")).toList();
    }
    final base =
        visible.where((e) => !e.deleted.contains("__archived__")).toList();
    if (selectedTab.value == "unread") {
      return base.where((e) => e.unreadCount > 0).toList();
    }
    if (selectedTab.value == "favorites") {
      return base;
    }
    return base;
  }

  Future<void> deleteChat(ChatListingModel item) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final conversationTs = int.tryParse(item.timeStamp) ?? 0;
    final deletedCutoff = conversationTs > now ? conversationTs : now;
    await _conversationRepository.setDeletedCutoff(
      currentUid: _uid,
      otherUserId: item.userID,
      chatId: item.chatID,
      deletedAt: deletedCutoff,
    );

    for (final entry in list) {
      if (entry.chatID != item.chatID) continue;
      entry.deleted = entry.deleted
          .where((value) => value != "__archived__" && value != "__deleted__")
          .toList()
        ..add("__deleted__");
    }
    list.refresh();
    if (search.text.trim().isEmpty) {
      _applyTabFilter();
    } else {
      _onSearchChanged();
    }
    _saveCachedList(list.toList());
  }

  void showCreateChatBottomSheet() {
    Get.bottomSheet(
      CreateChat(),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  void _listenCacheInvalidations() {
    _invalidationSub?.cancel();
    _invalidationSub = CacheInvalidationService.ensure()
        .watchType(
      CacheInvalidationEventType.messageUnsent,
    )
        .listen((event) {
      if (event.scopeId.trim().isEmpty) return;
      updateConversationPreviewLocal(
        chatId: event.scopeId,
        previewText: 'chat.unsent_message'.tr,
      );
    });
  }
}
