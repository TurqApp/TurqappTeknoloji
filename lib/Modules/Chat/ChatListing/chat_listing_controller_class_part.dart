part of 'chat_listing_controller.dart';

class ChatListingController extends _ChatListingControllerBase {
  static ChatListingController ensure() => _ensureChatListingController();

  static ChatListingController? maybeFind() =>
      _maybeFindChatListingController();
}
