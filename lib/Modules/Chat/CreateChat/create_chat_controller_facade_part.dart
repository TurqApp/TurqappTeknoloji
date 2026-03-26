part of 'create_chat_controller.dart';

CreateChatController ensureCreateChatController({bool permanent = false}) {
  final existing = maybeFindCreateChatController();
  if (existing != null) return existing;
  return Get.put(CreateChatController(), permanent: permanent);
}

CreateChatController? maybeFindCreateChatController() {
  final isRegistered = Get.isRegistered<CreateChatController>();
  if (!isRegistered) return null;
  return Get.find<CreateChatController>();
}
