part of 'message_content_controller.dart';

MessageContentController _ensureMessageContentController({
  required MessageModel model,
  required String mainID,
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindMessageContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    MessageContentController(model: model, mainID: mainID),
    tag: tag,
    permanent: permanent,
  );
}

MessageContentController? _maybeFindMessageContentController({String? tag}) {
  final isRegistered = Get.isRegistered<MessageContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<MessageContentController>(tag: tag);
}

void _handleMessageContentInit(MessageContentController controller) {
  controller.imageUrls.assignAll(controller.model.imgs);
  unawaited(controller._loadMessageUser());
  if (controller.model.postID != "") {
    controller.getPost();
  }
}
