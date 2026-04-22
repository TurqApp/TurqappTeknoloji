part of 'chat_controller.dart';

extension ChatControllerActionsPart on ChatController {
  void _listenCacheInvalidations() {
    _invalidationSubscription?.cancel();
    _invalidationSubscription = CacheInvalidationService.ensure().events.listen(
          _applyCacheInvalidationEvent,
        );
  }

  void _applyCacheInvalidationEvent(CacheInvalidationEvent event) {
    if (!event.isMessageEvent || event.scopeId != chatID) return;
    switch (event.type) {
      case CacheInvalidationEventType.messageDeletedForUser:
        _applyDeletedMessages(event.entityIds);
        return;
      case CacheInvalidationEventType.messageUnsent:
        _applyUnsentMessage(event.entityId);
        return;
      default:
        return;
    }
  }

  void _applyDeletedMessages(Iterable<String> messageIds) {
    final ids =
        messageIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) return;
    debugPrint(
      '[ChatDelete] stage=local_invalidation_received '
      'chatId=$chatID count=${ids.length} ids=${ids.join(",")}',
    );
    unawaited(_rememberLocalDeletedMessages(ids));
    final beforeLength = _conversationMessages.length;
    _conversationMessages.removeWhere(
      (key, message) {
        final rawId = message.rawDocID.trim();
        final normalizedDocId = message.docID
            .trim()
            .replaceFirst(RegExp(r'^conv_'), '');
        final normalizedKey = key.trim().replaceFirst(RegExp(r'^conv_'), '');
        return ids.contains(rawId) ||
            ids.contains(normalizedDocId) ||
            ids.contains(normalizedKey);
      },
    );
    selectedMessageIds.removeWhere(ids.contains);
    debugPrint(
      '[ChatDelete] stage=local_invalidation_applied '
      'chatId=$chatID before=$beforeLength after=${_conversationMessages.length}',
    );
    if (beforeLength == _conversationMessages.length) return;
    _refreshMergedMessages();
  }

  void _applyUnsentMessage(String messageId) {
    final normalizedId = messageId.trim();
    if (normalizedId.isEmpty) return;
    String? targetKey;
    for (final key in _conversationMessages.keys) {
      if (_conversationMessages[key]?.rawDocID == normalizedId) {
        targetKey = key;
        break;
      }
    }
    if (targetKey == null) return;
    final current = _conversationMessages[targetKey];
    if (current == null || current.isUnsent) return;
    _conversationMessages[targetKey] = MessageModel(
      docID: current.docID,
      rawDocID: current.rawDocID,
      source: current.source,
      timeStamp: current.timeStamp,
      userID: current.userID,
      lat: 0,
      long: 0,
      postType: '',
      postID: '',
      imgs: const <String>[],
      video: '',
      isRead: current.isRead,
      kullanicilar: current.kullanicilar,
      begeniler: current.begeniler,
      metin: '',
      sesliMesaj: '',
      kisiAdSoyad: '',
      kisiTelefon: '',
      isEdited: current.isEdited,
      isUnsent: true,
      isForwarded: current.isForwarded,
      replyMessageId: '',
      replySenderId: '',
      replyText: '',
      replyType: '',
      reactions: current.reactions,
      status: current.status,
      videoThumbnail: '',
      audioDurationMs: 0,
      isStarred: current.isStarred,
    );
    _refreshMergedMessages();
  }

  Future<void> toggleStarMessage(MessageModel model) async {
    try {
      await _conversationRepository.setMessageStar(
        chatId: chatID,
        messageId: model.rawDocID,
        isStarred: !model.isStarred,
      );
    } catch (_) {}
  }

  Future<void> deleteSelectedMessages() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty || selectedMessageIds.isEmpty) return;
    try {
      await _conversationRepository.deleteMessagesForUser(
        chatId: chatID,
        messageIds: selectedMessageIds,
        currentUid: uid,
      );
      final toRemove = Set<String>.from(selectedMessageIds);
      _conversationMessages
          .removeWhere((_, m) => toRemove.contains(m.rawDocID));
      selectedMessageIds.clear();
      isSelectionMode.value = false;
      _refreshMergedMessages();
    } catch (e) {
      AppSnackbar('common.error'.tr, 'chat.messages_delete_failed'.tr);
    }
  }

  Future<void> deleteSingleMessage(MessageModel model) async {
    final uid = CurrentUserService.instance.effectiveUserId.trim();
    final messageId = model.rawDocID.trim().isNotEmpty
        ? model.rawDocID.trim()
        : model.docID.trim().replaceFirst(RegExp(r'^conv_'), '');
    if (uid.isEmpty || messageId.isEmpty) return;
    try {
      debugPrint(
        '[ChatDelete] stage=chat_controller_delete_single '
        'chatId=$chatID messageId=$messageId uid=$uid '
        'rawDocID=${model.rawDocID} docID=${model.docID}',
      );
      await _conversationRepository.deleteMessageForUser(
        chatId: chatID,
        messageId: messageId,
        currentUid: uid,
      );
      _applyDeletedMessages(<String>[messageId]);
    } catch (_) {
      AppSnackbar('common.error'.tr, 'chat.messages_delete_failed'.tr);
    }
  }

  void _applyConversationSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool replace,
  }) {
    final currentUID = CurrentUserService.instance.effectiveUserId;
    if (replace) _conversationMessages.clear();
    final receiptSnapshots = <ChatReadReceiptSnapshot>[];

    for (final doc in docs) {
      final data = doc.data();
      final senderId = data["senderId"] ?? "";
      final deletedFor = List<String>.from(data["deletedFor"] ?? []);
      final createdDateRaw = data["createdDate"];
      final createdDateMs = createdDateRaw is Timestamp
          ? createdDateRaw.millisecondsSinceEpoch
          : createdDateRaw is num
              ? createdDateRaw.toInt()
              : int.tryParse("$createdDateRaw") ?? 0;
      if (deletedFor.contains(currentUID) ||
          (_deletedConversationCutoffMs > 0 &&
              createdDateMs > 0 &&
              createdDateMs <= _deletedConversationCutoffMs) ||
          _isLocallyDeletedMessageId(doc.id) ||
          _isLocallyDeletedMessageId('conv_${doc.id}')) {
        _conversationMessages.removeWhere(
          (key, message) =>
              key == "conv_${doc.id}" ||
              message.rawDocID == doc.id ||
              message.docID == 'conv_${doc.id}',
        );
        continue;
      }
      final status = data["status"] ?? "";
      final seenBy = List<String>.from(data["seenBy"] ?? []);
      final model = MessageModel.fromConversationSnapshot(doc);
      _conversationMessages[model.docID] = model;
      receiptSnapshots.add(
        ChatReadReceiptSnapshot(
          rawDocId: doc.id,
          senderId: senderId.toString(),
          status: status.toString(),
          seenBy: seenBy,
          timestampMs: model.timeStamp.toInt(),
        ),
      );
    }

    final readPolicyPlan = conversationApplicationService.buildReadPolicyPlan(
      currentUid: currentUID,
      snapshots: receiptSnapshots,
    );

    if (readPolicyPlan.hasPendingRepositoryUpdates) {
      _conversationRepository
          .markMessagesSeenAndDelivered(
            chatId: chatID,
            currentUid: currentUID,
            seenMessageIds: readPolicyPlan.unseenRawDocIds,
            deliveredMessageIds: readPolicyPlan.undeliveredRawDocIds,
          )
          .catchError((_) => null);
    }

    if (readPolicyPlan.latestSeenTs > 0) {
      unawaited(ChatControllerSupportPart(this)._markConversationOpenedAt(
        readPolicyPlan.latestSeenTs,
      ));
    }
  }

  void _refreshMergedMessages() {
    final merged = <MessageModel>[..._conversationMessages.values];
    merged.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    messages.value = merged;
    _syncConversationPreviewLocal(merged);
    unawaited(_saveLocalConversationWindow(merged));
  }

  void _syncConversationPreviewLocal(List<MessageModel> merged) {
    final listing = ChatListingController.maybeFind();
    if (listing == null) return;
    final latest = merged.isEmpty ? null : merged.first;
    listing.updateConversationPreviewLocal(
      chatId: chatID,
      previewText: latest == null ? '' : _buildPreviewTextForMessage(latest),
      timestampMs: latest?.timeStamp.toInt() ?? 0,
    );
  }

  String _buildPreviewTextForMessage(MessageModel message) {
    if (message.isUnsent) return 'chat.unsent_message'.tr;
    if (message.metin.trim().isNotEmpty) return message.metin.trim();
    if (message.video.trim().isNotEmpty) return 'chat.video'.tr;
    if (message.sesliMesaj.trim().isNotEmpty) return 'chat.audio'.tr;
    if (message.imgs.isNotEmpty) return 'chat.photo'.tr;
    if (message.postID.trim().isNotEmpty) return 'chat.post'.tr;
    if (message.kisiAdSoyad.trim().isNotEmpty) return 'chat.person'.tr;
    if (message.lat != 0 || message.long != 0) return 'chat.location'.tr;
    return '';
  }
}
