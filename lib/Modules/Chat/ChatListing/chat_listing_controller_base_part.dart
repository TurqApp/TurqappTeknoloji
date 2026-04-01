part of 'chat_listing_controller.dart';

abstract class _ChatListingControllerBase extends GetxController {
  final _state = _ChatListingControllerState();
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _handleChatListingInit(this as ChatListingController);
  }

  @override
  void onClose() {
    _handleChatListingClose(this as ChatListingController);
    super.onClose();
  }
}
