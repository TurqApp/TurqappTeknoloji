part of 'chat_controller.dart';

void _handleChatControllerInit(ChatController controller) {
  controller._initializeChatRuntime();
}

void _handleChatControllerClose(ChatController controller) {
  controller._disposeChatRuntimeResources();
}
