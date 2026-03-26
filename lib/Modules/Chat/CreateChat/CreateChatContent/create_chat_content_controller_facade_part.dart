part of 'create_chat_content_controller.dart';

CreateChatContentController ensureCreateChatContentController({
  required String userID,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindCreateChatContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CreateChatContentController(userID: userID),
    tag: tag,
    permanent: permanent,
  );
}

CreateChatContentController? maybeFindCreateChatContentController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<CreateChatContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CreateChatContentController>(tag: tag);
}
