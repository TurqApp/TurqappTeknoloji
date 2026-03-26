part of 'chat_controller.dart';

class ChatController extends GetxController {
  String chatID, userID;
  final _state = _ChatControllerState();

  ChatController({required this.chatID, required this.userID});

  @override
  void onInit() {
    super.onInit();
    _handleChatControllerInit(this);
  }

  @override
  void onClose() {
    _handleChatControllerClose(this);
    super.onClose();
  }
}
