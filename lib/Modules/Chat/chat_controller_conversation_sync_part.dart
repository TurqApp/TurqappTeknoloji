part of 'chat_controller.dart';

extension _ChatControllerConversationSyncX on ChatController {
  void _listenRealtimeMessages({bool cacheOnly = false}) {
    _messagesSubscription = _conversationRepository
        .watchConversationMessagesHead(
      chatID,
      limit: _syncHeadSize,
      cacheOnly: cacheOnly,
    )
        .listen((snapshot) {
      if (!_isOffline && !cacheOnly) {
        _messageSyncTimer?.cancel();
        _messageSyncTimer = null;
      } else if (!_isOffline && cacheOnly && _messageSyncTimer == null) {
        _messageSyncTimer = Timer.periodic(_serverSyncGap, (_) {
          _syncMessages(forceServer: true);
        });
      }
      if (cacheOnly) {
        _applyConversationSnapshot(snapshot.docs, replace: false);
        _refreshMergedMessages();
        return;
      }
      if (snapshot.docs.isEmpty) return;
      final previousHeadSignature = _realtimeHeadSignature;
      final nextHeadSignature = _buildHeadSignature(snapshot.docs);
      _realtimeHeadSignature = nextHeadSignature;
      final latestRemoteTs = _extractCreatedDateMs(snapshot.docs.first.data());
      final shouldSync = ChatRealtimeSyncPolicy.shouldTriggerSync(
        previousHeadSignature: previousHeadSignature,
        nextHeadSignature: nextHeadSignature,
        latestLoadedTimestampMs: _latestLoadedTimestampMs(),
        latestRemoteTimestampMs: latestRemoteTs,
      );
      if (shouldSync) {
        unawaited(_syncMessages(forceServer: true));
      }
    }, onError: (_) {
      if (_messageSyncTimer != null) return;
      _messageSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        _syncMessages(forceServer: true);
      });
    });
  }

  Future<void> _loadInitialMessages({required bool forceServer}) async {
    final cacheOnly = _isOffline;
    final shouldHitServer = !cacheOnly && forceServer;
    try {
      final conversationSnapshot =
          await _conversationRepository.fetchLatestMessages(
        chatID,
        limit: _initialPageSize,
        preferCache: !shouldHitServer,
        cacheOnly: cacheOnly,
      );

      _applyConversationSnapshot(conversationSnapshot.docs, replace: true);
      _conversationOldestCursor = conversationSnapshot.docs.isNotEmpty
          ? conversationSnapshot.docs.last
          : _conversationOldestCursor;

      _conversationHasMore =
          conversationSnapshot.docs.length >= _initialPageSize;
      _updateHasMoreOlder();
      _refreshMergedMessages();
      _lastServerSyncAt = DateTime.now();
    } catch (_) {}
  }

  Future<void> _syncMessages({required bool forceServer}) async {
    if (_isMessageSyncing) return;
    final cacheOnly = _isOffline;
    final shouldHitServer = !cacheOnly &&
        (forceServer ||
            _lastServerSyncAt == null ||
            DateTime.now().difference(_lastServerSyncAt!) > _serverSyncGap);
    _isMessageSyncing = true;
    try {
      final latestLoadedTs = _latestLoadedTimestampMs();
      final conversationSnapshot = latestLoadedTs > 0
          ? await _conversationRepository.fetchMessagesAfter(
              chatID,
              createdAfterMs: latestLoadedTs,
              limit: _syncHeadSize,
              preferCache: !shouldHitServer,
              cacheOnly: cacheOnly,
            )
          : await _conversationRepository.fetchLatestMessages(
              chatID,
              limit: _syncHeadSize,
              preferCache: !shouldHitServer,
              cacheOnly: cacheOnly,
            );

      _applyConversationSnapshot(conversationSnapshot.docs, replace: false);
      _refreshMergedMessages();

      if (shouldHitServer) {
        _lastServerSyncAt = DateTime.now();
      }
    } catch (_) {
    } finally {
      _isMessageSyncing = false;
    }
  }

  Future<void> loadOlderMessages() async {
    if (_isLoadingOlder) return;
    if (!_conversationHasMore) return;
    _isLoadingOlder = true;
    isLoadingOlder.value = true;
    try {
      final cacheOnly = _isOffline;
      if (_conversationHasMore && _conversationOldestCursor != null) {
        final convSnapshot = await _conversationRepository.fetchOlderMessages(
          chatID,
          startAfter: _conversationOldestCursor!,
          limit: _olderPageSize,
          preferCache: true,
          cacheOnly: cacheOnly,
        );
        _applyConversationSnapshot(convSnapshot.docs, replace: false);
        if (convSnapshot.docs.isNotEmpty) {
          _conversationOldestCursor = convSnapshot.docs.last;
        }
        _conversationHasMore = convSnapshot.docs.length >= _olderPageSize;
      }

      _updateHasMoreOlder();
      _refreshMergedMessages();
    } catch (_) {
    } finally {
      _isLoadingOlder = false;
      isLoadingOlder.value = false;
    }
  }

  Future<void> jumpToMessageByRawId(String rawId) async {
    if (rawId.trim().isEmpty) return;

    int index = messages.indexWhere((m) => m.rawDocID == rawId);
    var attempts = 0;
    while (index < 0 && attempts < 4 && hasMoreOlder.value) {
      await loadOlderMessages();
      index = messages.indexWhere((m) => m.rawDocID == rawId);
      attempts++;
    }

    if (index < 0) {
      AppSnackbar('common.info'.tr, 'chat.reply_target_missing'.tr);
      return;
    }

    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final target =
        (index * 120.0).clamp(0.0, position.maxScrollExtent).toDouble();
    await scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  void _updateHasMoreOlder() {
    hasMoreOlder.value = _conversationHasMore;
  }

  int _latestLoadedTimestampMs() {
    var latest = 0;
    for (final m in _conversationMessages.values) {
      final ts = m.timeStamp.toInt();
      if (ts > latest) latest = ts;
    }
    return latest;
  }

  int _extractCreatedDateMs(Map<String, dynamic> data) {
    final raw = data["createdDate"];
    if (raw is Timestamp) return raw.millisecondsSinceEpoch;
    if (raw is num) return raw.toInt();
    return int.tryParse("$raw") ?? 0;
  }

  int _extractUpdatedDateMs(Map<String, dynamic> data) {
    final raw = data["updatedDate"];
    if (raw is Timestamp) return raw.millisecondsSinceEpoch;
    if (raw is num) return raw.toInt();
    return int.tryParse("$raw") ?? 0;
  }

  String _buildHeadSignature(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return ChatRealtimeSyncPolicy.buildHeadSignature(
      docs.map((doc) {
        final data = doc.data();
        final reactions = data['reactions'];
        final seenBy = data['seenBy'];
        final likes = data['likes'];
        final deletedFor = data['deletedFor'];
        var reactionSelectionCount = 0;
        if (reactions is Map) {
          for (final value in reactions.values) {
            if (value is List) {
              reactionSelectionCount += value.length;
            }
          }
        }
        return ChatRealtimeHeadEntry(
          id: doc.id,
          createdDateMs: _extractCreatedDateMs(data),
          updatedDateMs: _extractUpdatedDateMs(data),
          status: (data['status'] ?? '').toString(),
          isEdited: data['isEdited'] == true,
          isUnsent: data['unsent'] == true,
          seenByCount: seenBy is List ? seenBy.length : 0,
          reactionBucketCount: reactions is Map ? reactions.length : 0,
          reactionSelectionCount: reactionSelectionCount,
          likeCount: likes is List ? likes.length : 0,
          deletedForCount: deletedFor is List ? deletedFor.length : 0,
        );
      }),
    );
  }
}
