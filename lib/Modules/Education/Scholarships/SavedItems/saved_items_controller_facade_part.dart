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

void invalidateSavedItemsScreenCacheForUser(
  String userId, {
  bool? isLiked,
}) {
  final cleanUserId = userId.trim();
  if (cleanUserId.isEmpty) return;
  _SavedItemsControllerBase._screenCache.removeWhere((key, _) {
    if (isLiked == null) return key.endsWith(':$cleanUserId');
    final kind = isLiked ? 'liked' : 'bookmarked';
    return key == '$kind:$cleanUserId';
  });
}
