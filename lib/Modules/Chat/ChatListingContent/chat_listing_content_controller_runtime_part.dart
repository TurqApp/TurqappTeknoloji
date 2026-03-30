part of 'chat_listing_content_controller.dart';

extension ChatListingContentControllerRuntimePart
    on ChatListingContentController {
  void _handleChatListingContentOnInit() {
    notReadCounter.value = model.unreadCount;
    _bindListingState();
    if (model.lastMessage.trim().isEmpty) return;
    lastMessage.assignAll([_buildPreviewMessage(model)]);
  }

  void _bindListingState() {
    final listing = ChatListingController.maybeFind();
    if (listing == null) return;
    _listWorker = ever<List<ChatListingModel>>(listing.list, (_) {
      final latest =
          listing.list.firstWhereOrNull((e) => e.chatID == model.chatID);
      if (latest == null) return;
      model = latest;
      notReadCounter.value = latest.unreadCount;
      if (latest.lastMessage.trim().isEmpty) {
        lastMessage.clear();
        return;
      }
      lastMessage.assignAll([_buildPreviewMessage(latest)]);
    });
  }

  MessageModel _buildPreviewMessage(ChatListingModel listing) {
    return MessageModel(
      docID: 'preview_${listing.chatID}',
      rawDocID: 'preview_${listing.chatID}',
      source: 'preview',
      timeStamp: num.tryParse(listing.timeStamp) ?? 0,
      userID: listing.userID,
      lat: 0,
      long: 0,
      postType: '',
      postID: '',
      imgs: const [],
      video: '',
      isRead: listing.unreadCount <= 0,
      kullanicilar: const [],
      metin: listing.lastMessage,
      sesliMesaj: '',
      kisiAdSoyad: '',
      kisiTelefon: '',
      begeniler: const [],
      isEdited: false,
      isUnsent: false,
      isForwarded: false,
      replyMessageId: '',
      replySenderId: '',
      replyText: '',
      replyType: '',
      reactions: const {},
    );
  }

  void _handleChatListingContentOnClose() {
    _listWorker?.dispose();
  }
}
