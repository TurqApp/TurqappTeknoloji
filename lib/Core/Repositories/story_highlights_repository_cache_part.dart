part of 'story_highlights_repository.dart';

extension StoryHighlightsRepositoryCachePart on StoryHighlightsRepository {
  List<StoryHighlightModel>? _getFromMemory(
    String uid, {
    required bool allowStale,
  }) {
    final entry = _memory[uid];
    if (entry == null) return null;
    final fresh = DateTime.now().difference(entry.cachedAt) <=
        StoryHighlightsRepository._ttl;
    if (!fresh && !allowStale) return null;
    return entry.items.map(_clone).toList(growable: false);
  }

  Future<_CachedStoryHighlights?> _getFromPrefsEntry(
    String uid, {
    required bool allowStale,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey(uid));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final list =
          (decoded['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      if (ts <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final fresh =
          DateTime.now().difference(cachedAt) <= StoryHighlightsRepository._ttl;
      if (!fresh && !allowStale) return null;
      return _CachedStoryHighlights(
        cachedAt: cachedAt,
        items: list
            .map(
              (e) => StoryHighlightModel(
                id: (e['id'] ?? '').toString(),
                userId: (e['userId'] ?? '').toString(),
                title: (e['title'] ?? '').toString(),
                coverUrl: (e['coverUrl'] ?? '').toString(),
                storyIds: (e['storyIds'] as List?)?.cast<String>() ??
                    const <String>[],
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                  (e['createdDate'] as num?)?.toInt() ??
                      DateTime.now().millisecondsSinceEpoch,
                ),
                order: (e['order'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }

  StoryHighlightModel _clone(StoryHighlightModel item) => StoryHighlightModel(
        id: item.id,
        userId: item.userId,
        title: item.title,
        coverUrl: item.coverUrl,
        storyIds: List<String>.from(item.storyIds),
        createdAt: item.createdAt,
        order: item.order,
      );

  String _prefsKey(String uid) =>
      '${StoryHighlightsRepository._prefsPrefix}:$uid';
}
