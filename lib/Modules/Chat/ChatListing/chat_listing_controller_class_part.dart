part of 'chat_listing_controller.dart';

class ChatListingController extends GetxController {
  static ChatListingController ensure() => _ensureChatListingController();

  static ChatListingController? maybeFind() =>
      _maybeFindChatListingController();

  final _state = _ChatListingControllerState();
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();

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
