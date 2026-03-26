part of 'story_seens_controller.dart';

StorySeensController ensureStorySeensController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindStorySeensController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    StorySeensController(),
    tag: tag,
    permanent: permanent,
  );
}

StorySeensController? maybeFindStorySeensController({String? tag}) {
  final isRegistered = Get.isRegistered<StorySeensController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<StorySeensController>(tag: tag);
}

extension StorySeensControllerFacadePart on StorySeensController {
  Future<void> getData(String storyID) async {
    try {
      list.assignAll(await _storyRepository.fetchStoryViewerIds(storyID));
    } catch (_) {
      list.clear();
    }

    try {
      totalSeen.value = await _storyRepository.fetchStoryViewerCount(storyID);
    } catch (_) {
      totalSeen.value = 0;
    }
  }
}
