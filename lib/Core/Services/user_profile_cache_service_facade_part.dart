part of 'user_profile_cache_service.dart';

UserProfileCacheService ensureUserProfileCacheService() {
  final existing = maybeFindUserProfileCacheService();
  if (existing != null) return existing;
  return Get.put(UserProfileCacheService(), permanent: true);
}

UserProfileCacheService? maybeFindUserProfileCacheService() {
  final isRegistered = Get.isRegistered<UserProfileCacheService>();
  if (!isRegistered) return null;
  return Get.find<UserProfileCacheService>();
}

Future<void> invalidateUserProfileCacheIfRegistered(String uid) async {
  await maybeFindUserProfileCacheService()?.invalidateUser(uid);
}
