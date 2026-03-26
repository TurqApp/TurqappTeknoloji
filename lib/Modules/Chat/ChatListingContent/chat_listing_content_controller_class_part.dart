part of 'chat_listing_content_controller.dart';

class ChatListingContentController extends GetxController {
  final _ChatListingContentControllerState _state;

  ChatListingContentController({
    required String userID,
    required ChatListingModel model,
  }) : _state = _ChatListingContentControllerState(
          userID: userID,
          model: model,
        );

  @override
  void onInit() {
    super.onInit();
    _handleChatListingContentOnInit();
  }

  @override
  void onClose() {
    _handleChatListingContentOnClose();
    super.onClose();
  }
}
