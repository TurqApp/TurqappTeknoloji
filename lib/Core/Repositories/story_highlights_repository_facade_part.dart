part of 'story_highlights_repository.dart';

StoryHighlightsRepository? maybeFindStoryHighlightsRepository() =>
    Get.isRegistered<StoryHighlightsRepository>()
        ? Get.find<StoryHighlightsRepository>()
        : null;

StoryHighlightsRepository ensureStoryHighlightsRepository() =>
    maybeFindStoryHighlightsRepository() ??
    Get.put(StoryHighlightsRepository(), permanent: true);
