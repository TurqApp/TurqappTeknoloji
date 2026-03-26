part of 'saved_items_controller.dart';

SavedItemsController ensureSavedItemsController({
  required String tag,
  bool permanent = false,
}) {
  final existing = maybeFindSavedItemsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(SavedItemsController(), tag: tag, permanent: permanent);
}

SavedItemsController? maybeFindSavedItemsController({required String tag}) {
  final isRegistered = Get.isRegistered<SavedItemsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SavedItemsController>(tag: tag);
}
