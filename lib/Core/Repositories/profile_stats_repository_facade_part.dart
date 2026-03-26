part of 'profile_stats_repository.dart';

ProfileStatsRepository? maybeFindProfileStatsRepository() {
  final isRegistered = Get.isRegistered<ProfileStatsRepository>();
  if (!isRegistered) return null;
  return Get.find<ProfileStatsRepository>();
}

ProfileStatsRepository ensureProfileStatsRepository() {
  final existing = maybeFindProfileStatsRepository();
  if (existing != null) return existing;
  return Get.put(ProfileStatsRepository(), permanent: true);
}
