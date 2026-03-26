part of 'chat_listing_controller.dart';

class ChatListingController extends _ChatListingControllerBase {
  static ChatListingController ensure() => _ensureChatListingController();

  static ChatListingController? maybeFind() =>
      _maybeFindChatListingController();

  @override
  void onInit() {
    super.onInit();
    _handleChatListingInit(this);
  }

  @override
  void onClose() {
    _handleChatListingClose(this);
    super.onClose();
  }
}
