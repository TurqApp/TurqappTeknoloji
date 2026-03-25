part of 'story_highlights_repository.dart';

class _CachedStoryHighlights {
  final List<StoryHighlightModel> items;
  final DateTime cachedAt;

  const _CachedStoryHighlights({
    required this.items,
    required this.cachedAt,
  });
}
