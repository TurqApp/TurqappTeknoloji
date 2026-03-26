part of 'chat_listing_content_controller.dart';

class ChatListingContentController extends _ChatListingContentControllerBase {
  ChatListingContentController({
    required String userID,
    required ChatListingModel model,
  }) : super(
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
