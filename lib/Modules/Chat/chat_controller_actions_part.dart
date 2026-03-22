part of 'chat_controller.dart';

extension ChatControllerActionsPart on ChatController {
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

  void _applyConversationSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool replace,
  }) {
    final currentUID = CurrentUserService.instance.effectiveUserId;
    if (replace) _conversationMessages.clear();
    final List<String> unseenRawDocIds = [];
    final List<String> undeliveredRawDocIds = [];
    int latestSeenTs = 0;

    for (final doc in docs) {
      final data = doc.data();
      final senderId = data["senderId"] ?? "";
      final deletedFor = List<String>.from(data["deletedFor"] ?? []);
      if (deletedFor.contains(currentUID)) {
        _conversationMessages.remove("conv_${doc.id}");
        continue;
      }
      final status = data["status"] ?? "";
      final seenBy = List<String>.from(data["seenBy"] ?? []);
      final model = MessageModel.fromConversationSnapshot(doc);
      _conversationMessages[model.docID] = model;
      final ts = model.timeStamp.toInt();
      if (ts > latestSeenTs) latestSeenTs = ts;

      if (senderId != currentUID && !seenBy.contains(currentUID)) {
        unseenRawDocIds.add(doc.id);
      }

      // Mark other user's "sent" messages as "delivered" when we see them
      if (senderId != currentUID && status == "sent") {
        undeliveredRawDocIds.add(doc.id);
      }
    }

    if (unseenRawDocIds.isNotEmpty || undeliveredRawDocIds.isNotEmpty) {
      _conversationRepository
          .markMessagesSeenAndDelivered(
            chatId: chatID,
            currentUid: currentUID,
            seenMessageIds: unseenRawDocIds,
            deliveredMessageIds: undeliveredRawDocIds,
          )
          .catchError((_) => null);
    }

    if (latestSeenTs > 0) {
      unawaited(_markConversationOpenedAt(latestSeenTs));
    }
  }

  void _refreshMergedMessages() {
    final merged = <MessageModel>[..._conversationMessages.values];
    merged.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    messages.value = merged;
    unawaited(_saveLocalConversationWindow(merged));
  }
}
