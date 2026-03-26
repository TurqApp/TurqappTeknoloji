part of 'post_interaction_service.dart';

PostInteractionService? maybeFindPostInteractionService() {
  final isRegistered = Get.isRegistered<PostInteractionService>();
  if (!isRegistered) return null;
  return Get.find<PostInteractionService>();
}

PostInteractionService ensurePostInteractionService() {
  final existing = maybeFindPostInteractionService();
  if (existing != null) return existing;
  return Get.put(PostInteractionService());
}
