part of 'conversation_repository.dart';

const int _conversationPreviewHeadLimit = 180;

class _ConversationParticipantPreviewState {
  const _ConversationParticipantPreviewState({
    required this.previewText,
    required this.previewTimestampMs,
  });

  final String previewText;
  final int previewTimestampMs;
}

extension ConversationRepositoryMessagePart on ConversationRepository {
  Future<List<String>> _collectMessageMediaUrls(
    String chatId,
    Iterable<String> messageIds,
  ) async {
    final normalizedIds = messageIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedIds.isEmpty) return const <String>[];

    final urls = <String>{};
    for (final messageId in normalizedIds) {
      try {
        final snap = await _messageRef(chatId, messageId).get(
          const GetOptions(source: Source.serverAndCache),
        );
        final data = snap.data();
        if (!snap.exists || data == null || data.isEmpty) continue;
        final mediaUrls = data['mediaUrls'];
        if (mediaUrls is Iterable) {
          for (final value in mediaUrls) {
            final url = value?.toString().trim() ?? '';
            if (url.isNotEmpty) urls.add(url);
          }
        }
        final videoUrl = (data['videoUrl'] ?? '').toString().trim();
        final videoThumbnail = (data['videoThumbnail'] ?? '').toString().trim();
        final audioUrl = (data['audioUrl'] ?? '').toString().trim();
        if (videoUrl.isNotEmpty) urls.add(videoUrl);
        if (videoThumbnail.isNotEmpty) urls.add(videoThumbnail);
        if (audioUrl.isNotEmpty) urls.add(audioUrl);
      } catch (_) {}
    }
    return urls.toList(growable: false);
  }

  Future<void> _purgeMessageMediaUrls(
    String chatId,
    Iterable<String> messageIds,
  ) async {
    final urls = await _collectMessageMediaUrls(chatId, messageIds);
    if (urls.isEmpty) return;
    await TurqImageCacheManager.removeUrls(urls);
  }

  List<String> _sanitizeReactionUsers(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  int _conversationMessageTimestampMs(Map<String, dynamic> data) {
    final raw = data['createdDate'];
    if (raw is Timestamp) return raw.millisecondsSinceEpoch;
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }

  String _conversationMessageSenderId(Map<String, dynamic> data) {
    return (data['senderId'] ?? '').toString().trim();
  }

  bool _conversationMessageVisibleForUser(
    Map<String, dynamic> data,
    String uid,
  ) {
    final deletedFor = (data['deletedFor'] as List?)
            ?.map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toSet() ??
        const <String>{};
    return !deletedFor.contains(uid);
  }

  bool _conversationMessageUnreadForUser(
    Map<String, dynamic> data,
    String uid,
  ) {
    if (!_conversationMessageVisibleForUser(data, uid)) return false;
    if (_conversationMessageSenderId(data) == uid) return false;
    if (data['unsent'] == true) return false;
    final seenBy = (data['seenBy'] as List?)
            ?.map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toSet() ??
        const <String>{};
    return !seenBy.contains(uid);
  }

  String _buildConversationPreviewToken(Map<String, dynamic> data) {
    if (data['unsent'] == true) return 'chat.unsent_message';

    final text = (data['text'] ?? '').toString().trim();
    if (text.isNotEmpty) return text;

    final videoUrl = (data['videoUrl'] ?? '').toString().trim();
    if (videoUrl.isNotEmpty) return 'chat.video';

    final audioUrl = (data['audioUrl'] ?? '').toString().trim();
    if (audioUrl.isNotEmpty) return 'chat.audio';

    final mediaUrls = data['mediaUrls'];
    if (mediaUrls is Iterable && mediaUrls.isNotEmpty) {
      return 'chat.photo';
    }

    final postRef = data['postRef'];
    if (postRef is Map &&
        (postRef['postId'] ?? '').toString().trim().isNotEmpty) {
      return 'chat.post';
    }

    final contact = data['contact'];
    if (contact is Map &&
        (contact['name'] ?? '').toString().trim().isNotEmpty) {
      return 'chat.person';
    }

    final location = data['location'];
    if (location is Map) {
      final lat = location['lat'];
      final lng = location['lng'];
      final latValue = lat is num ? lat : num.tryParse('${lat ?? ''}') ?? 0;
      final lngValue = lng is num ? lng : num.tryParse('${lng ?? ''}') ?? 0;
      if (latValue != 0 || lngValue != 0) {
        return 'chat.location';
      }
    }

    return '';
  }

  Future<List<Map<String, dynamic>>> _fetchConversationMessagesByIds(
    String chatId,
    Iterable<String> messageIds,
  ) async {
    final normalizedIds = messageIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedIds.isEmpty) return const <Map<String, dynamic>>[];

    final messages = <Map<String, dynamic>>[];
    for (final messageId in normalizedIds) {
      try {
        final snap = await _messageRef(chatId, messageId).get(
          const GetOptions(source: Source.serverAndCache),
        );
        final data = snap.data();
        if (!snap.exists || data == null || data.isEmpty) continue;
        messages.add(Map<String, dynamic>.from(data));
      } catch (_) {}
    }
    return messages;
  }

  Future<_ConversationParticipantPreviewState>
      _resolveConversationParticipantPreviewState(
    String chatId,
    String uid,
  ) async {
    try {
      final snapshot = await fetchLatestMessages(
        chatId,
        limit: _conversationPreviewHeadLimit,
        preferCache: false,
        cacheOnly: false,
      );
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!_conversationMessageVisibleForUser(data, uid)) continue;
        return _ConversationParticipantPreviewState(
          previewText: _buildConversationPreviewToken(data),
          previewTimestampMs: _conversationMessageTimestampMs(data),
        );
      }
    } catch (_) {}
    return const _ConversationParticipantPreviewState(
      previewText: '',
      previewTimestampMs: 0,
    );
  }

  Future<void> _setConversationParticipantPreviewState({
    required String chatId,
    required String uid,
    required _ConversationParticipantPreviewState previewState,
    int? unreadCount,
  }) async {
    final update = <String, dynamic>{
      'previewText.$uid': previewState.previewText,
      'previewAt.$uid': previewState.previewTimestampMs,
    };
    if (unreadCount != null) {
      update['unread.$uid'] = unreadCount < 0 ? 0 : unreadCount;
    }
    await _firestore
        .collection('conversations')
        .doc(chatId)
        .set(update, SetOptions(merge: true));
  }

  int _countUnreadMessagesForUser(
    Iterable<Map<String, dynamic>> messages,
    String uid,
  ) {
    var count = 0;
    for (final data in messages) {
      if (_conversationMessageUnreadForUser(data, uid)) {
        count++;
      }
    }
    return count;
  }

  Future<void> _commitMessageUpdatesInChunks(
    String chatId,
    Iterable<String> messageIds, {
    required Map<String, dynamic> update,
    int chunkSize = 200,
  }) async {
    final ids = messageIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids.isEmpty) return;

    for (var start = 0; start < ids.length; start += chunkSize) {
      final batch = _firestore.batch();
      final end = (start + chunkSize).clamp(0, ids.length).toInt();
      for (final messageId in ids.sublist(start, end)) {
        batch.set(
          _messageRef(chatId, messageId),
          update,
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  Future<void> deleteMessageForUser({
    required String chatId,
    required String messageId,
    required String currentUid,
  }) async {
    final conversation = await getConversation(
      chatId,
      preferCache: true,
      cacheOnly: false,
    );
    final currentUnread = participantIntValue(
      conversation?['unread'],
      currentUid,
      defaultValue: 0,
    );
    final affectedMessages = await _fetchConversationMessagesByIds(
      chatId,
      <String>[messageId],
    );
    final unreadDelta = _countUnreadMessagesForUser(
      affectedMessages,
      currentUid,
    );
    final mediaPurge = _purgeMessageMediaUrls(chatId, <String>[messageId]);
    await _messageRef(chatId, messageId).set({
      "deletedFor": FieldValue.arrayUnion([currentUid]),
      "updatedDate": DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    await mediaPurge;
    final previewState = await _resolveConversationParticipantPreviewState(
      chatId,
      currentUid,
    );
    await _setConversationParticipantPreviewState(
      chatId: chatId,
      uid: currentUid,
      previewState: previewState,
      unreadCount: (currentUnread - unreadDelta).clamp(0, 1 << 30).toInt(),
    );
    CacheInvalidationService.ensure().publish(
      CacheInvalidationEvent.messageDeletedForUser(
        chatId: chatId,
        messageIds: <String>[messageId],
        userId: currentUid,
      ),
    );
  }

  Future<void> deleteMessagesForUser({
    required String chatId,
    required Iterable<String> messageIds,
    required String currentUid,
  }) async {
    final ids = messageIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) return;
    final conversation = await getConversation(
      chatId,
      preferCache: true,
      cacheOnly: false,
    );
    final currentUnread = participantIntValue(
      conversation?['unread'],
      currentUid,
      defaultValue: 0,
    );
    final affectedMessages = await _fetchConversationMessagesByIds(chatId, ids);
    final unreadDelta = _countUnreadMessagesForUser(
      affectedMessages,
      currentUid,
    );
    final mediaPurge = _purgeMessageMediaUrls(chatId, ids);
    await _commitMessageUpdatesInChunks(
      chatId,
      ids,
      update: {
        "deletedFor": FieldValue.arrayUnion([currentUid]),
        "updatedDate": DateTime.now().millisecondsSinceEpoch,
      },
    );
    await mediaPurge;
    final previewState = await _resolveConversationParticipantPreviewState(
      chatId,
      currentUid,
    );
    await _setConversationParticipantPreviewState(
      chatId: chatId,
      uid: currentUid,
      previewState: previewState,
      unreadCount: (currentUnread - unreadDelta).clamp(0, 1 << 30).toInt(),
    );
    CacheInvalidationService.ensure().publish(
      CacheInvalidationEvent.messageDeletedForUser(
        chatId: chatId,
        messageIds: ids,
        userId: currentUid,
      ),
    );
  }

  Future<void> unsendMessage({
    required String chatId,
    required String messageId,
  }) async {
    final conversation = await getConversation(
      chatId,
      preferCache: true,
      cacheOnly: false,
    );
    final participants = conversation == null
        ? const <String>[]
        : resolveConversationParticipants(conversation);
    final affectedMessages = await _fetchConversationMessagesByIds(
      chatId,
      <String>[messageId],
    );
    final mediaPurge = _purgeMessageMediaUrls(chatId, <String>[messageId]);
    await _messageRef(chatId, messageId).update({
      "unsent": true,
      "text": "",
      "mediaUrls": <String>[],
      "videoUrl": "",
      "videoThumbnail": "",
      "audioUrl": "",
      "audioDurationMs": 0,
      "location": FieldValue.delete(),
      "contact": FieldValue.delete(),
      "postRef": FieldValue.delete(),
      "replyTo": FieldValue.delete(),
      "updatedDate": DateTime.now().millisecondsSinceEpoch,
    });
    await mediaPurge;
    for (final participantUid in participants) {
      final currentUnread = participantIntValue(
        conversation?['unread'],
        participantUid,
        defaultValue: 0,
      );
      final unreadDelta = _countUnreadMessagesForUser(
        affectedMessages,
        participantUid,
      );
      final previewState = await _resolveConversationParticipantPreviewState(
        chatId,
        participantUid,
      );
      await _setConversationParticipantPreviewState(
        chatId: chatId,
        uid: participantUid,
        previewState: previewState,
        unreadCount: (currentUnread - unreadDelta).clamp(0, 1 << 30).toInt(),
      );
    }
    CacheInvalidationService.ensure().publish(
      CacheInvalidationEvent.messageUnsent(
        chatId: chatId,
        messageId: messageId,
      ),
    );
  }

  Future<void> setMessageStar({
    required String chatId,
    required String messageId,
    required bool isStarred,
  }) async {
    await _messageRef(chatId, messageId).set({
      "isStarred": isStarred,
      "updatedDate": DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> updateMessageText({
    required String chatId,
    required String messageId,
    required String text,
  }) async {
    final conversation = await getConversation(
      chatId,
      preferCache: true,
      cacheOnly: false,
    );
    final participants = conversation == null
        ? const <String>[]
        : resolveConversationParticipants(conversation);
    await _messageRef(chatId, messageId).update({
      "text": text,
      "isEdited": true,
      "updatedDate": DateTime.now().millisecondsSinceEpoch,
    });
    for (final participantUid in participants) {
      final previewState = await _resolveConversationParticipantPreviewState(
        chatId,
        participantUid,
      );
      await _setConversationParticipantPreviewState(
        chatId: chatId,
        uid: participantUid,
        previewState: previewState,
      );
    }
  }

  Future<void> toggleMessageReaction({
    required String chatId,
    required String messageId,
    required String currentUid,
    required String emoji,
  }) async {
    final ref = _messageRef(chatId, messageId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? const <String, dynamic>{};
      final reactions = Map<String, dynamic>.from(data["reactions"] ?? {});
      final selectedUsers = _sanitizeReactionUsers(reactions[emoji]);
      final wasSelected = selectedUsers.contains(currentUid);

      final updates = <String, dynamic>{};
      for (final entry in reactions.entries) {
        final key = entry.key.toString();
        final users = _sanitizeReactionUsers(entry.value);
        if (users.contains(currentUid)) {
          updates["reactions.$key"] = FieldValue.arrayRemove([currentUid]);
        }
      }

      if (!wasSelected) {
        updates["reactions.$emoji"] = FieldValue.arrayUnion([currentUid]);
      }
      updates["updatedDate"] = DateTime.now().millisecondsSinceEpoch;

      tx.update(ref, updates);
    });
  }

  Future<void> toggleMessageLike({
    required String chatId,
    required String messageId,
    required String currentUid,
    required bool isLiked,
  }) async {
    await _messageRef(chatId, messageId).update({
      "likes": isLiked
          ? FieldValue.arrayRemove([currentUid])
          : FieldValue.arrayUnion([currentUid]),
      "updatedDate": DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeMessageImage({
    required String chatId,
    required String messageId,
    required String imgUrl,
  }) async {
    await TurqImageCacheManager.removeUrl(imgUrl);
    await _messageRef(chatId, messageId).update({
      "mediaUrls": FieldValue.arrayRemove([imgUrl]),
      "updatedDate": DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> markMessagesSeenAndDelivered({
    required String chatId,
    required String currentUid,
    required Iterable<String> seenMessageIds,
    required Iterable<String> deliveredMessageIds,
  }) async {
    final seenIds = seenMessageIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final deliveredIds = deliveredMessageIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && !seenIds.contains(id))
        .toSet();
    if (seenIds.isEmpty && deliveredIds.isEmpty) return;

    await _commitMessageUpdatesInChunks(
      chatId,
      seenIds,
      update: {
        "seenBy": FieldValue.arrayUnion([currentUid]),
        "status": "read",
        "updatedDate": DateTime.now().millisecondsSinceEpoch,
      },
    );
    await _commitMessageUpdatesInChunks(
      chatId,
      deliveredIds,
      update: {
        "status": "delivered",
        "updatedDate": DateTime.now().millisecondsSinceEpoch,
      },
    );

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection("conversations").doc(chatId),
      {
        "unread.$currentUid": 0,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> addPostShareMessage({
    required String chatId,
    required String currentUid,
    required String postId,
    required String postType,
  }) async {
    await addMessage(
      chatId: chatId,
      payload: {
        "senderId": currentUid,
        "text": "",
        "createdDate": DateTime.now().millisecondsSinceEpoch,
        "seenBy": [currentUid],
        "type": "post",
        "mediaUrls": [],
        "likes": <String>[],
        "isDeleted": false,
        "isEdited": false,
        "audioUrl": "",
        "postRef": {
          "postId": postId,
          "postType": postType,
          "previewText": "",
          "previewImageUrl": "",
        }
      },
    );
  }

  Future<DocumentReference<Map<String, dynamic>>> addMessage({
    required String chatId,
    required Map<String, dynamic> payload,
  }) async {
    return _firestore
        .collection("conversations")
        .doc(chatId)
        .collection("messages")
        .add(payload);
  }
}
