part of 'story_highlights_repository.dart';

List<String> _cloneStoryHighlightStoryIds(List<String> storyIds) {
  final out = <String>[];
  for (final storyId in storyIds) {
    final normalized = storyId.trim();
    if (normalized.isEmpty) continue;
    out.add(normalized);
  }
  return out;
}

List<StoryHighlightModel> _cloneStoryHighlightItems(
  List<StoryHighlightModel> items,
) {
  return items
      .map(
        (item) => StoryHighlightModel(
          id: item.id,
          userId: item.userId,
          title: item.title,
          coverUrl: item.coverUrl,
          storyIds: _cloneStoryHighlightStoryIds(item.storyIds),
          createdAt: item.createdAt,
          order: item.order,
        ),
      )
      .toList(growable: false);
}

class _CachedStoryHighlights {
  final List<StoryHighlightModel> items;
  final DateTime cachedAt;

  _CachedStoryHighlights({
    required List<StoryHighlightModel> items,
    required this.cachedAt,
  }) : items = _cloneStoryHighlightItems(items);
}
