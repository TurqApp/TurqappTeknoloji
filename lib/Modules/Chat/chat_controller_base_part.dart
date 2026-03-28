part of 'chat_controller.dart';

abstract class _ChatControllerBase extends GetxController {
  _ChatControllerBase({
    required this.chatID,
    required this.userID,
    ChatConversationApplicationService? conversationApplicationService,
  }) : _state = _ChatControllerState(
          conversationApplicationService: conversationApplicationService,
        );

  final String chatID;
  final String userID;
  final _ChatControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleChatControllerInit(this as ChatController);
  }

  @override
  void onClose() {
    _handleChatControllerClose(this as ChatController);
    super.onClose();
  }
}
