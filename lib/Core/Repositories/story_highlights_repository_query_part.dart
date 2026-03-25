part of 'story_highlights_repository.dart';

extension StoryHighlightsRepositoryQueryPart on StoryHighlightsRepository {
  Future<List<StoryHighlightModel>> getHighlights(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    if (uid.isEmpty) return const <StoryHighlightModel>[];

    if (!forceRefresh) {
      final memory = _getFromMemory(uid, allowStale: false);
      if (preferCache && memory != null) return memory;
      final disk = await _getFromPrefsEntry(uid, allowStale: false);
      if (preferCache && disk != null) {
        _memory[uid] = _CachedStoryHighlights(
          items: disk.items.map(_clone).toList(growable: false),
          cachedAt: disk.cachedAt,
        );
        return disk.items.map(_clone).toList(growable: false);
      }
    }

    if (cacheOnly) return const <StoryHighlightModel>[];

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('highlights')
        .orderBy('order')
        .get();
    final list = snap.docs.map(StoryHighlightModel.fromDoc).toList();
    await setHighlights(uid, list);
    return list;
  }
}
