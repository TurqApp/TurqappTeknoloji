part of 'story_content_profile_controller.dart';

StoryContentProfileController ensureStoryContentProfileController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindStoryContentProfileController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    StoryContentProfileController(),
    tag: tag,
    permanent: permanent,
  );
}

StoryContentProfileController? maybeFindStoryContentProfileController({
  String? tag,
}) {
  final isRegistered =
      Get.isRegistered<StoryContentProfileController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<StoryContentProfileController>(tag: tag);
}
