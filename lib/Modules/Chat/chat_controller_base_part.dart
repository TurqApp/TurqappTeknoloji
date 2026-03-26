part of 'chat_controller.dart';

abstract class _ChatControllerBase extends GetxController {
  _ChatControllerBase({required this.chatID, required this.userID});

  final String chatID;
  final String userID;
  final _state = _ChatControllerState();

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
