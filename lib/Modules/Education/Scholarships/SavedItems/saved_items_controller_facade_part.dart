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

void syncSavedItemsInteractionForUser({
  required String userId,
  required String docId,
  required bool isLiked,
  required bool isSelected,
  Map<String, dynamic>? item,
}) {
  final cleanUserId = userId.trim();
  final cleanDocId = docId.trim();
  if (cleanUserId.isEmpty || cleanDocId.isEmpty) return;

  final kind = isLiked ? 'liked' : 'bookmarked';
  final key = '$kind:$cleanUserId';
  final cached = _SavedItemsControllerBase._screenCache[key];
  final items = cached == null
      ? <Map<String, dynamic>>[]
      : _cloneSavedItemsForSync(cached.items);

  items.removeWhere((candidate) => candidate['docId'] == cleanDocId);
  final syncItem = item ?? _findSavedItemForSync(cached?.items, cleanDocId);
  if (isSelected && syncItem != null) {
    final clonedItem = _cloneSavedItemForSync(syncItem)..['docId'] = cleanDocId;
    items.insert(0, clonedItem);
  }

  _SavedItemsControllerBase._interactionOverrides[
          _interactionOverrideKey(cleanUserId, kind, cleanDocId)] =
      _SavedItemsInteractionOverride(
    isSelected: isSelected,
    createdAt: DateTime.now(),
    item: syncItem == null ? null : _cloneSavedItemForSync(syncItem),
  );

  if (isSelected || cached != null) {
    _SavedItemsControllerBase._screenCache[key] = _CachedSavedItemsList(
      items: _cloneSavedItemsForSync(items),
      cachedAt: DateTime.now(),
    );
  }

  for (final controller in _SavedItemsControllerBase._liveControllers) {
    final target = isLiked
        ? controller.likedScholarships
        : controller.bookmarkedScholarships;
    target.removeWhere((candidate) => candidate['docId'] == cleanDocId);
    if (isSelected && syncItem != null) {
      target.insert(
          0, _cloneSavedItemForSync(syncItem)..['docId'] = cleanDocId);
    }
  }

  debugPrint(
    '[SavedItemsSync] kind=$kind docId=$cleanDocId selected=$isSelected '
    'cacheCount=${items.length} liveControllers='
    '${_SavedItemsControllerBase._liveControllers.length} seeded=${syncItem != null}',
  );
}

List<Map<String, dynamic>> applySavedItemsInteractionOverridesForUser({
  required String userId,
  required bool isLiked,
  required List<Map<String, dynamic>> items,
}) {
  final cleanUserId = userId.trim();
  if (cleanUserId.isEmpty) return items;
  final kind = isLiked ? 'liked' : 'bookmarked';
  final now = DateTime.now();
  final merged = _cloneSavedItemsForSync(items);
  final staleKeys = <String>[];

  for (final entry in _SavedItemsControllerBase._interactionOverrides.entries) {
    final key = entry.key;
    final override = entry.value;
    if (!key.startsWith('$kind:$cleanUserId:')) continue;
    if (now.difference(override.createdAt) >
        _SavedItemsControllerBase.interactionOverrideTtl) {
      staleKeys.add(key);
      continue;
    }

    final docId = key.substring('$kind:$cleanUserId:'.length);
    merged.removeWhere((candidate) => candidate['docId'] == docId);
    if (override.isSelected && override.item != null) {
      merged.insert(
          0, _cloneSavedItemForSync(override.item!)..['docId'] = docId);
    }
  }

  for (final key in staleKeys) {
    _SavedItemsControllerBase._interactionOverrides.remove(key);
  }

  return merged;
}

String _interactionOverrideKey(String userId, String kind, String docId) =>
    '$kind:$userId:$docId';

Map<String, dynamic> _cloneSavedItemForSync(Map<String, dynamic> item) =>
    Map<String, dynamic>.from(item);

Map<String, dynamic>? _findSavedItemForSync(
  List<Map<String, dynamic>>? items,
  String docId,
) {
  if (items == null) return null;
  for (final item in items) {
    if (item['docId'] == docId) return item;
  }
  return null;
}

List<Map<String, dynamic>> _cloneSavedItemsForSync(
  List<Map<String, dynamic>> items,
) =>
    items.map(_cloneSavedItemForSync).toList();
