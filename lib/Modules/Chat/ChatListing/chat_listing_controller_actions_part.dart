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
    _invalidationSub = CacheInvalidationService.ensure().events.listen((event) {
      switch (event.type) {
        case CacheInvalidationEventType.messageDeletedForUser:
        case CacheInvalidationEventType.messageUnsent:
          if (event.scopeId.trim().isEmpty) return;
          unawaited(_refreshConversationPreviewFromHead(event.scopeId));
          return;
        default:
          return;
      }
    });
  }

  Future<void> _refreshConversationPreviewFromHead(String chatId) async {
    final normalizedChatId = chatId.trim();
    final uid = _uid.trim();
    if (normalizedChatId.isEmpty || uid.isEmpty) return;
    try {
      final snapshot = await _conversationRepository.fetchLatestMessages(
        normalizedChatId,
        limit: 12,
        preferCache: true,
        cacheOnly: false,
      );
      Map<String, dynamic>? latestVisible;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final deletedFor = (data['deletedFor'] as List?)
                ?.map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false) ??
            const <String>[];
        if (deletedFor.contains(uid)) continue;
        latestVisible = data;
        break;
      }
      updateConversationPreviewLocal(
        chatId: normalizedChatId,
        previewText: latestVisible == null
            ? ''
            : _buildConversationPreviewFromData(latestVisible),
        timestampMs: latestVisible == null
            ? 0
            : _extractConversationPreviewTimestampMs(latestVisible),
      );
    } catch (_) {}
  }

  int _extractConversationPreviewTimestampMs(Map<String, dynamic> data) {
    final raw = data['createdDate'];
    if (raw is Timestamp) return raw.millisecondsSinceEpoch;
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }

  num _conversationPreviewAsNum(Object? value) {
    if (value is num) return value;
    return num.tryParse('${value ?? ''}') ?? 0;
  }

  String _buildConversationPreviewFromData(Map<String, dynamic> data) {
    if (data['unsent'] == true) return 'chat.unsent_message'.tr;

    final text = (data['text'] ?? '').toString().trim();
    if (text.isNotEmpty) return text;

    final videoUrl = (data['videoUrl'] ?? '').toString().trim();
    if (videoUrl.isNotEmpty) return 'chat.video'.tr;

    final audioUrl = (data['audioUrl'] ?? '').toString().trim();
    if (audioUrl.isNotEmpty) return 'chat.audio'.tr;

    final mediaUrls = data['mediaUrls'];
    if (mediaUrls is Iterable && mediaUrls.isNotEmpty) {
      return 'chat.photo'.tr;
    }

    final postRef = data['postRef'];
    if (postRef is Map &&
        (postRef['postId'] ?? '').toString().trim().isNotEmpty) {
      return 'chat.post'.tr;
    }

    final contact = data['contact'];
    if (contact is Map &&
        (contact['name'] ?? '').toString().trim().isNotEmpty) {
      return 'chat.person'.tr;
    }

    final location = data['location'];
    if (location is Map) {
      final lat = _conversationPreviewAsNum(location['lat']);
      final lng = _conversationPreviewAsNum(location['lng']);
      if (lat != 0 || lng != 0) {
        return 'chat.location'.tr;
      }
    }

    return '';
  }
}
