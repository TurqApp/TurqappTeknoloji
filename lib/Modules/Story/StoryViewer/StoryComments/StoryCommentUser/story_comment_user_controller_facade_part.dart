part of 'story_comment_user_controller.dart';

StoryCommentUserController ensureStoryCommentUserController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindStoryCommentUserController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    StoryCommentUserController(),
    tag: tag,
    permanent: permanent,
  );
}

StoryCommentUserController? maybeFindStoryCommentUserController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<StoryCommentUserController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<StoryCommentUserController>(tag: tag);
}
