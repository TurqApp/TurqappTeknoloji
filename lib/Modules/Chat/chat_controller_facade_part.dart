part of 'chat_controller.dart';

ChatController ensureChatController({
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

ChatController? maybeFindChatController({String? tag}) =>
    _resolveRegisteredChatController(tag: tag);
