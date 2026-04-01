part of 'chat_listing_content_controller.dart';

ChatListingContentController ensureChatListingContentController({
  required String userID,
  required ChatListingModel model,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindChatListingContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ChatListingContentController(userID: userID, model: model),
    tag: tag,
    permanent: permanent,
  );
}

ChatListingContentController? maybeFindChatListingContentController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<ChatListingContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ChatListingContentController>(tag: tag);
}
