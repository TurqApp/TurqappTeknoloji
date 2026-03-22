part of 'chat_controller.dart';

extension ChatControllerForwardingPart on ChatController {
  Future<void> sendExternalText(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await sendMessage(textOverride: clean);
  }

  Future<void> sendExternalReplyText(
    String text, {
    required String replyText,
    required String replyType,
    required String replyTarget,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await sendMessage(
      textOverride: clean,
      replyTextOverride: replyText,
      replyTypeOverride: replyType,
      replySenderIdOverride: CurrentUserService.instance.effectiveUserId,
      replyMessageIdOverride: replyTarget,
    );
  }

  Future<void> toggleReaction(MessageModel model, String emoji) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty || emoji.trim().isEmpty) return;
    await _conversationRepository.toggleMessageReaction(
      chatId: chatID,
      messageId: model.rawDocID,
      currentUid: uid,
      emoji: emoji.trim(),
    );
  }

  Future<void> unsendMessage(MessageModel model) async {
    final currentUID = CurrentUserService.instance.effectiveUserId;
    if (model.userID != currentUID) return;

    await _conversationRepository.unsendMessage(
      chatId: chatID,
      messageId: model.rawDocID,
    );
  }

  Future<void> _editMessage(MessageModel model, String newText) async {
    await _conversationRepository.updateMessageText(
      chatId: chatID,
      messageId: model.rawDocID,
      text: newText,
    );
  }

  Future<void> openForwardPicker(MessageModel model) async {
    final currentUID = CurrentUserService.instance.effectiveUserId;
    if (currentUID.isEmpty) return;
    final docs = await _conversationRepository.fetchUserConversations(
      currentUID,
      preferCache: true,
      cacheOnly: false,
    );
    final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      docs,
    )..sort((a, b) {
        final aTs = ((a.data()["lastMessageAt"] ?? 0) as num).toInt();
        final bTs = ((b.data()["lastMessageAt"] ?? 0) as num).toInt();
        return bTs.compareTo(aTs);
      });
    final snapDocs = sortedDocs.take(30).toList(growable: false);

    final items = <Map<String, String>>[];
    final otherIds = <String>[];
    for (final doc in snapDocs) {
      if (doc.id == chatID) continue;
      final participants = List<String>.from(doc.data()["participants"] ?? []);
      final other = participants.firstWhereOrNull((v) => v != currentUID);
      if (other == null || other.isEmpty) continue;
      otherIds.add(other);
    }

    final userMap = await _userSummaryResolver.resolveMany(otherIds);
    for (final doc in snapDocs) {
      if (doc.id == chatID) continue;
      final participants = List<String>.from(doc.data()["participants"] ?? []);
      final other = participants.firstWhereOrNull((v) => v != currentUID);
      if (other == null || other.isEmpty) continue;
      final userData = userMap[other];
      if (userData == null) continue;
      items.add({
        "chatID": doc.id,
        "userID": other,
        "nickname": userData.preferredName,
      });
    }

    if (items.isEmpty) {
      AppSnackbar("common.info".tr, "chat.forward_target_missing".tr);
      return;
    }

    Get.bottomSheet(
      SafeArea(
        child: Container(
          color: Colors.white,
          child: ListView(
            shrinkWrap: true,
            children: items
                .map(
                  (e) => ListTile(
                    title: Text(
                      e["nickname"] ?? "",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                    onTap: () async {
                      Get.back();
                      await forwardMessage(model, e["chatID"]!, e["userID"]!);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> forwardMessage(
      MessageModel model, String targetChatId, String targetUserId) async {
    final currentUID = CurrentUserService.instance.effectiveUserId;
    if (currentUID.isEmpty) return;

    final convMessage = {
      "senderId": currentUID,
      "text": model.metin,
      "createdDate": DateTime.now().millisecondsSinceEpoch,
      "seenBy": [currentUID],
      "type": model.postID.isNotEmpty
          ? "post"
          : model.kisiAdSoyad.isNotEmpty
              ? "contact"
              : model.lat != 0
                  ? "location"
                  : model.imgs.isNotEmpty
                      ? "media"
                      : "text",
      "mediaUrls": model.imgs,
      "likes": <String>[],
      "isDeleted": false,
      "isEdited": false,
      "forwarded": true,
      "unsent": false,
      "reactions": <String, List<String>>{},
      if (model.kisiAdSoyad.isNotEmpty)
        "contact": {
          "name": model.kisiAdSoyad,
          "phone": model.kisiTelefon,
        },
      if (model.lat != 0)
        "location": {
          "lat": model.lat,
          "lng": model.long,
          "name": model.metin,
        },
      if (model.postID.isNotEmpty)
        "postRef": {
          "postId": model.postID,
          "postType": model.postType,
          "previewText": "",
          "previewImageUrl": "",
        },
      "forwardedFrom": {
        "conversationId": chatID,
        "messageId": model.rawDocID,
        "senderName": nickname.value,
      }
    };

    final previewText =
        model.metin.isNotEmpty ? model.metin : 'chat.forwarded_body'.tr;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _conversationRepository.upsertConversationEnvelope(
      chatId: targetChatId,
      currentUid: currentUID,
      otherUid: targetUserId,
      lastMessage: previewText,
      nowMs: nowMs,
    );

    await _conversationRepository.addMessage(
      chatId: targetChatId,
      payload: Map<String, dynamic>.from(convMessage),
    );

    AppSnackbar('chat.forwarded_title'.tr, 'chat.forwarded_body'.tr);
    ChatListingController.maybeFind()?.getList();
  }
}
