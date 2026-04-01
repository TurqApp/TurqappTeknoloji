part of 'chat_listing_content_controller.dart';

abstract class _ChatListingContentControllerBase extends GetxController {
  _ChatListingContentControllerBase({
    required String userID,
    required ChatListingModel model,
  }) : _state = _ChatListingContentControllerState(
          userID: userID,
          model: model,
        );

  final _ChatListingContentControllerState _state;

  @override
  void onInit() {
    super.onInit();
    (this as ChatListingContentController)._handleChatListingContentOnInit();
  }

  @override
  void onClose() {
    (this as ChatListingContentController)._handleChatListingContentOnClose();
    super.onClose();
  }
}
