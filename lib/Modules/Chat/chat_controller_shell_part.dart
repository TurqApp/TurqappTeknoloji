part of 'chat_controller.dart';

class ChatController extends _ChatControllerBase {
  static ChatController ensure({
    required String chatID,
    required String userID,
    String? tag,
    bool permanent = false,
  }) =>
      ensureChatController(
        chatID: chatID,
        userID: userID,
        tag: tag,
        permanent: permanent,
      );

  static ChatController? maybeFind({String? tag}) =>
      maybeFindChatController(tag: tag);

  ChatController({
    required super.chatID,
    required super.userID,
    super.conversationApplicationService,
  });
}
