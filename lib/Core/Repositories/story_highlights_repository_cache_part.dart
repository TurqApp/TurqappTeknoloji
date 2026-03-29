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
    if (!fresh && !allowStale) {
      _memory.remove(uid);
      return null;
    }
    return entry.items.map(_clone).toList(growable: false);
  }

  Future<_CachedStoryHighlights?> _getFromPrefsEntry(
    String uid, {
    required bool allowStale,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = _prefsKey(uid);
    final raw = prefs?.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final rawItems = decoded['items'];
      if (rawItems is! List) {
        await prefs?.remove(prefsKey);
        return null;
      }
      if (ts <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final fresh =
          DateTime.now().difference(cachedAt) <= StoryHighlightsRepository._ttl;
      if (!fresh) {
        if (!allowStale) {
          await prefs?.remove(prefsKey);
        }
        return null;
      }
      var shouldPersist = false;
      final items = <StoryHighlightModel>[];
      for (final rawItem in rawItems) {
        if (rawItem is! Map) {
          shouldPersist = true;
          continue;
        }
        try {
          final item =
              Map<String, dynamic>.from(rawItem.cast<dynamic, dynamic>());
          final storyIdsRaw = item['storyIds'];
          final storyIds = <String>[];
          if (storyIdsRaw is List) {
            for (final rawStoryId in storyIdsRaw) {
              final storyId = rawStoryId?.toString().trim() ?? '';
              if (storyId.isEmpty) {
                shouldPersist = true;
                continue;
              }
              storyIds.add(storyId);
            }
          } else if (storyIdsRaw != null) {
            shouldPersist = true;
          }
          final highlight = StoryHighlightModel(
            id: (item['id'] ?? '').toString(),
            userId: (item['userId'] ?? '').toString(),
            title: (item['title'] ?? '').toString(),
            coverUrl: (item['coverUrl'] ?? '').toString(),
            storyIds: storyIds,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (item['createdDate'] as num?)?.toInt() ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
            order: (item['order'] as num?)?.toInt() ?? 0,
          );
          if (highlight.id.trim().isEmpty) {
            shouldPersist = true;
            continue;
          }
          items.add(highlight);
        } catch (_) {
          shouldPersist = true;
        }
      }
      if (items.isEmpty) {
        await prefs?.remove(prefsKey);
        return null;
      }
      if (shouldPersist || items.length != rawItems.length) {
        await prefs?.setString(
          prefsKey,
          jsonEncode(<String, dynamic>{
            't': ts,
            'items': items
                .map(
                  (item) => <String, dynamic>{
                    'id': item.id,
                    'userId': item.userId,
                    'title': item.title,
                    'coverUrl': item.coverUrl,
                    'storyIds': List<String>.from(item.storyIds),
                    'createdDate': item.createdAt.millisecondsSinceEpoch,
                    'order': item.order,
                  },
                )
                .toList(growable: false),
          }),
        );
      }
      return _CachedStoryHighlights(
        cachedAt: cachedAt,
        items: items,
      );
    } catch (_) {
      await prefs?.remove(prefsKey);
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
