part of 'chat_controller.dart';

extension ChatControllerForwardingPart on ChatController {
  String _chatListingCacheKey(String uid) =>
      uid.trim().isEmpty ? '' : 'chat_listing_cache_${uid.trim()}';

  List<ChatListingModel> _sortForwardCandidates(
      Iterable<ChatListingModel> items) {
    final sorted = items
        .map((item) => ChatListingModel.fromJson(item.toJson()))
        .toList(growable: false);
    sorted.sort((a, b) {
      final aTs = int.tryParse(a.timeStamp) ?? 0;
      final bTs = int.tryParse(b.timeStamp) ?? 0;
      return bTs.compareTo(aTs);
    });
    return sorted;
  }

  Future<List<ChatListingModel>> _loadForwardCandidatesFromCache(
    String currentUID,
  ) async {
    final controller = ChatListingController.maybeFind();
    if (controller != null && controller.list.isNotEmpty) {
      return _sortForwardCandidates(controller.list);
    }

    final key = _chatListingCacheKey(currentUID);
    if (key.isEmpty) return const <ChatListingModel>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return const <ChatListingModel>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ChatListingModel>[];
      final restored = decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatListingModel.fromJson)
          .toList(growable: false);
      return _sortForwardCandidates(restored);
    } catch (_) {
      return const <ChatListingModel>[];
    }
  }

  Future<String> _resolvedWriteUserId() async {
    final ensured = await CurrentUserService.instance.ensureAuthReady(
      waitForAuthState: true,
      forceTokenRefresh: true,
      timeout: const Duration(seconds: 8),
    );
    final authUid = (ensured ?? '').trim();
    if (authUid.isNotEmpty) return authUid;
    return CurrentUserService.instance.authUserId.trim();
  }

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
      replySenderIdOverride: await _resolvedWriteUserId(),
      replyMessageIdOverride: replyTarget,
    );
  }

  Future<void> toggleReaction(MessageModel model, String emoji) async {
    final uid = await _resolvedWriteUserId();
    if (uid.isEmpty || emoji.trim().isEmpty) return;
    await _conversationRepository.toggleMessageReaction(
      chatId: chatID,
      messageId: model.rawDocID,
      currentUid: uid,
      emoji: emoji.trim(),
    );
  }

  Future<void> unsendMessage(MessageModel model) async {
    final currentUID = await _resolvedWriteUserId();
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
    final currentUID = await _resolvedWriteUserId();
    if (currentUID.isEmpty) return;
    final items = <Map<String, String>>[];
    final cachedChats = (await _loadForwardCandidatesFromCache(currentUID))
        .where((item) => item.chatID != chatID && item.userID.trim().isNotEmpty)
        .take(30)
        .toList(growable: false);
    if (cachedChats.isNotEmpty) {
      final unresolvedIds = cachedChats
          .where((item) =>
              item.nickname.trim().isEmpty && item.fullName.trim().isEmpty)
          .map((item) => item.userID.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
      final userMap = unresolvedIds.isEmpty
          ? <String, dynamic>{}
          : await _userSummaryResolver.resolveMany(unresolvedIds);
      for (final item in cachedChats) {
        final cachedName = item.nickname.trim().isNotEmpty
            ? item.nickname.trim()
            : item.fullName.trim();
        final fallbackName = userMap[item.userID]?.preferredName ?? '';
        final displayName = cachedName.isNotEmpty ? cachedName : fallbackName;
        if (displayName.isEmpty) continue;
        items.add({
          "chatID": item.chatID,
          "userID": item.userID,
          "nickname": displayName,
        });
      }
    } else {
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

      final otherIds = <String>[];
      for (final doc in snapDocs) {
        if (doc.id == chatID) continue;
        final participants =
            List<String>.from(doc.data()["participants"] ?? []);
        final other = participants.firstWhereOrNull((v) => v != currentUID);
        if (other == null || other.isEmpty) continue;
        otherIds.add(other);
      }

      final userMap = await _userSummaryResolver.resolveMany(otherIds);
      for (final doc in snapDocs) {
        if (doc.id == chatID) continue;
        final participants =
            List<String>.from(doc.data()["participants"] ?? []);
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
    final currentUID = await _resolvedWriteUserId();
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
