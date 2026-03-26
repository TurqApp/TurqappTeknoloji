part of 'story_highlights_repository.dart';

StoryHighlightsRepository? maybeFindStoryHighlightsRepository() {
  final isRegistered = Get.isRegistered<StoryHighlightsRepository>();
  if (!isRegistered) return null;
  return Get.find<StoryHighlightsRepository>();
}

StoryHighlightsRepository ensureStoryHighlightsRepository() {
  final existing = maybeFindStoryHighlightsRepository();
  if (existing != null) return existing;
  return Get.put(StoryHighlightsRepository(), permanent: true);
}
