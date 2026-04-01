part of 'profile_stats_repository.dart';

ProfileStatsRepository? maybeFindProfileStatsRepository() =>
    Get.isRegistered<ProfileStatsRepository>()
        ? Get.find<ProfileStatsRepository>()
        : null;

ProfileStatsRepository ensureProfileStatsRepository() =>
    maybeFindProfileStatsRepository() ??
    Get.put(ProfileStatsRepository(), permanent: true);
