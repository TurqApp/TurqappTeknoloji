part of 'chat_controller.dart';

class ChatController extends GetxController {
  static ChatController ensure({
    required String chatID,
    required String userID,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureChatController(
        chatID: chatID,
        userID: userID,
        tag: tag,
        permanent: permanent,
      );

  static ChatController? maybeFind({String? tag}) =>
      _resolveRegisteredChatController(tag: tag);

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
