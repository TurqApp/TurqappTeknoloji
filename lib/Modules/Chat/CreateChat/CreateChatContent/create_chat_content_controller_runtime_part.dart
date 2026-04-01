part of 'create_chat_content_controller.dart';

void _handleCreateChatContentInit(CreateChatContentController controller) {
  unawaited(controller._loadUser());
}

Future<void> _loadCreateChatContentUser(
  CreateChatContentController controller,
) async {
  final user = await controller._userSummaryResolver.resolve(
    controller.userID,
    preferCache: true,
  );
  if (user == null) return;
  controller.nickname.value = user.nickname.isNotEmpty
      ? user.nickname
      : (user.username.isNotEmpty ? user.username : user.displayName);
  controller.avatarUrl.value = user.avatarUrl;
  controller.fullName.value = user.displayName;
}

extension CreateChatContentControllerRuntimePart
    on CreateChatContentController {
  Future<void> _loadUser() => _loadCreateChatContentUser(this);
}
