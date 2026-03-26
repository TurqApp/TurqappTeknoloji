part of 'location_share_controller.dart';

LocationShareController ensureLocationShareController({
  required String chatID,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindLocationShareController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    LocationShareController(chatID: chatID),
    tag: tag,
    permanent: permanent,
  );
}

LocationShareController? maybeFindLocationShareController({String? tag}) {
  final isRegistered = Get.isRegistered<LocationShareController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<LocationShareController>(tag: tag);
}
