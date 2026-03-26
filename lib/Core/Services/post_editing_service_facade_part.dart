part of 'post_editing_service.dart';

PostEditingService? maybeFindPostEditingService() {
  final isRegistered = Get.isRegistered<PostEditingService>();
  if (!isRegistered) return null;
  return Get.find<PostEditingService>();
}

PostEditingService ensurePostEditingService() {
  final existing = maybeFindPostEditingService();
  if (existing != null) return existing;
  return Get.put(PostEditingService());
}
