part of 'follow_repository.dart';

FollowRepository? maybeFindFollowRepository() {
  final isRegistered = Get.isRegistered<FollowRepository>();
  if (!isRegistered) return null;
  return Get.find<FollowRepository>();
}

FollowRepository ensureFollowRepository() {
  final existing = maybeFindFollowRepository();
  if (existing != null) return existing;
  return Get.put(FollowRepository(), permanent: true);
}
