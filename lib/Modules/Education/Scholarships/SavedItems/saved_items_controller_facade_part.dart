part of 'saved_items_controller_library.dart';

SavedItemsController ensureSavedItemsController({
  required String tag,
  bool permanent = false,
}) =>
    maybeFindSavedItemsController(tag: tag) ??
    Get.put(SavedItemsController(), tag: tag, permanent: permanent);

SavedItemsController? maybeFindSavedItemsController({required String tag}) =>
    Get.isRegistered<SavedItemsController>(tag: tag)
        ? Get.find<SavedItemsController>(tag: tag)
        : null;
