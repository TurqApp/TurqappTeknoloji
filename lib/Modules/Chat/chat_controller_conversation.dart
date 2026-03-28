part of 'chat_controller.dart';

extension _ChatControllerConversationX on ChatController {
  Future<void> _clearConversationUnread() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      await _conversationRepository.setUnreadCount(
        chatId: chatID,
        currentUid: uid,
        unreadCount: 0,
      );
    } catch (_) {}
  }

  void _syncUnreadIndicatorsLocal() {
    maybeFindUnreadMessagesController()?.updateConversationUnreadLocal(
      otherUid: userID,
      unreadCount: 0,
      chatId: chatID,
      seenAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    InAppNotificationsController.maybeFind()
        ?.markChatNotificationsReadLocal(chatId: chatID);
  }

  Future<void> _markConversationOpenedNow() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      conversationApplicationService.buildOpenedStorageKey(
        uid: uid,
        chatId: chatID,
      ),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _markConversationOpenedAt(int timestampMs) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = conversationApplicationService.buildOpenedStorageKey(
      uid: uid,
      chatId: chatID,
    );
    final old = prefs.getInt(key) ?? 0;
    if (conversationApplicationService.shouldPersistOpenedAt(
      previousOpenedAtMs: old,
      candidateTimestampMs: timestampMs,
    )) {
      await prefs.setInt(key, timestampMs);
    }
  }

  void getUserData() async {
    try {
      final data = (await ensureUserProfileCacheService().getProfile(
            userID,
            preferCache: true,
            cacheOnly: _isOffline,
          )) ??
          <String, dynamic>{};

      nickname.value =
          (data["nickname"] ?? data["username"] ?? data["displayName"] ?? "")
              .toString();
      avatarUrl.value = (data["avatarUrl"] ?? "").toString();
      token.value = (data["token"] ?? "").toString();

      final firstName = (data["firstName"] ?? "").toString().trim();
      final lastName = (data["lastName"] ?? "").toString().trim();
      final full = "$firstName $lastName".trim();
      fullName.value = full.isNotEmpty
          ? full
          : (data["fullName"] ?? nickname.value).toString();
      bio.value = (data["bio"] ?? "").toString();

      followersCount.value = _asInt(
          data["followersCount"] ?? data["takipci"] ?? data["followerCount"]);
      followingCount.value = _asInt(
          data["followingCount"] ?? data["takip"] ?? data["followCount"]);
      postCount.value =
          _asInt(data["postCount"] ?? data["gonderi"] ?? data["postsCount"]);
    } catch (_) {}
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is List) return value.length;
    return 0;
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTypingChanged() {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final text = textEditingController.text;
    if (text.isNotEmpty) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final shouldSendHeartbeat = !_typingActive ||
          (nowMs - _lastTypingHeartbeatMs) >= _typingHeartbeatIntervalMs;
      if (shouldSendHeartbeat) {
        try {
          _conversationRepository.setTypingTimestamp(
            chatId: chatID,
            currentUid: uid,
            timestampMs: nowMs,
          );
          _typingActive = true;
          _lastTypingHeartbeatMs = nowMs;
        } catch (_) {}
      }
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(seconds: 2), _clearTyping);
    } else {
      _clearTyping();
    }
  }

  void _clearTyping() {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    if (!_typingActive) return;
    try {
      _conversationRepository.setTypingTimestamp(
        chatId: chatID,
        currentUid: uid,
        timestampMs: 0,
      );
      _typingActive = false;
      _lastTypingHeartbeatMs = 0;
    } catch (_) {}
  }

  void _listenTypingState() {
    _typingStream = _conversationRepository.watchConversation(chatID).listen((
      doc,
    ) {
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      _recipientMuted =
          _conversationRepository.participantBoolValue(data["muted"], userID);
      final otherTs = _conversationRepository.participantIntValue(
        data["typing"],
        userID,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      isOtherTyping.value = otherTs > 0 && (now - otherTs) < 3000;

      int lastMessageAtMs = 0;
      final lmAt = data["lastMessageAt"];
      if (lmAt is Timestamp) {
        lastMessageAtMs = lmAt.millisecondsSinceEpoch;
      } else {
        final fallback = data["lastMessageAtMs"];
        lastMessageAtMs =
            fallback is int ? fallback : int.tryParse("$fallback") ?? 0;
      }
      if (lastMessageAtMs > 0) {
        unawaited(_markConversationOpenedAt(lastMessageAtMs));
      }
    });
  }

  Future<void> getData() async {
    _messageSyncTimer?.cancel();
    _messagesSubscription?.cancel();
    _realtimeHeadSignature = '';

    final hasLocalWindow = await _loadLocalConversationWindow();
    await _loadInitialMessages(forceServer: !hasLocalWindow);
    _listenRealtimeMessages(cacheOnly: hasLocalWindow);
    if (_isOffline) {
      _messageSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        unawaited(
          _ChatControllerConversationSyncX(this)._syncMessages(
            forceServer: false,
          ),
        );
      });
    }
  }

  Future<void> loadChatBackgroundPreference() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final data = await _conversationRepository.getConversation(
            chatID,
            preferCache: true,
            cacheOnly: false,
          ) ??
          const <String, dynamic>{};
      final legacyRaw = data["chatBgIndex"];
      final legacyIdx = legacyRaw is int
          ? legacyRaw
          : legacyRaw is num
              ? legacyRaw.toInt()
              : int.tryParse("$legacyRaw") ?? 0;
      var idx = _conversationRepository.participantIntValue(
        data["chatBg"],
        uid,
        defaultValue: legacyIdx,
      );
      _recipientMuted =
          _conversationRepository.participantBoolValue(data["muted"], userID);
      if (idx < 0) idx = 0;
      if (idx > 5) idx = 5;
      chatBgPaletteIndex.value = idx;
    } catch (_) {}
  }

  Future<void> setChatBackgroundPreference(int index) async {
    if (index < 0 || index > 5) return;
    chatBgPaletteIndex.value = index;
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      await _conversationRepository.setChatBackgroundIndex(
        chatId: chatID,
        currentUid: uid,
        index: index,
      );
    } catch (_) {}
  }
}
