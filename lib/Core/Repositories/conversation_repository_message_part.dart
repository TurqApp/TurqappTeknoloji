part of 'conversation_repository.dart';

extension ConversationRepositoryMessagePart on ConversationRepository {
  Future<void> deleteMessageForUser({
    required String chatId,
    required String messageId,
    required String currentUid,
  }) async {
    await _messageRef(chatId, messageId).set({
      "deletedFor": FieldValue.arrayUnion([currentUid]),
    }, SetOptions(merge: true));
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
    final batch = _firestore.batch();
    for (final messageId in ids) {
      batch.set(
        _messageRef(chatId, messageId),
        {
          "deletedFor": FieldValue.arrayUnion([currentUid]),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> unsendMessage({
    required String chatId,
    required String messageId,
  }) async {
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
    });
  }

  Future<void> setMessageStar({
    required String chatId,
    required String messageId,
    required bool isStarred,
  }) async {
    await _messageRef(chatId, messageId).set({
      "isStarred": isStarred,
    }, SetOptions(merge: true));
  }

  Future<void> updateMessageText({
    required String chatId,
    required String messageId,
    required String text,
  }) async {
    await _messageRef(chatId, messageId).update({
      "text": text,
      "isEdited": true,
    });
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
      final selectedUsers = List<String>.from(reactions[emoji] ?? const []);
      final wasSelected = selectedUsers.contains(currentUid);

      final updates = <String, dynamic>{};
      for (final entry in reactions.entries) {
        final key = entry.key.toString();
        final users = List<String>.from(entry.value ?? const []);
        if (users.contains(currentUid)) {
          updates["reactions.$key"] = FieldValue.arrayRemove([currentUid]);
        }
      }

      if (!wasSelected) {
        updates["reactions.$emoji"] = FieldValue.arrayUnion([currentUid]);
      }

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
    });
  }

  Future<void> removeMessageImage({
    required String chatId,
    required String messageId,
    required String imgUrl,
  }) async {
    await _messageRef(chatId, messageId).update({
      "mediaUrls": FieldValue.arrayRemove([imgUrl]),
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

    final batch = _firestore.batch();
    for (final messageId in seenIds.take(25)) {
      batch.update(_messageRef(chatId, messageId), {
        "seenBy": FieldValue.arrayUnion([currentUid]),
        "status": "read",
      });
    }
    for (final messageId in deliveredIds.take(25)) {
      batch.update(_messageRef(chatId, messageId), {
        "status": "delivered",
      });
    }
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
