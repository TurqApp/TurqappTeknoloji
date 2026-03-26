part of 'story_highlights_controller.dart';

StoryHighlightsController ensureStoryHighlightsController({
  required String userId,
  required String tag,
}) {
  final existing = maybeFindStoryHighlightsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(StoryHighlightsController(userId: userId), tag: tag);
}

StoryHighlightsController? maybeFindStoryHighlightsController({
  required String tag,
}) {
  final isRegistered = Get.isRegistered<StoryHighlightsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<StoryHighlightsController>(tag: tag);
}
