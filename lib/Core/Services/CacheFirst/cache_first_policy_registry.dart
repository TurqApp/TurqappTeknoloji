import 'cache_first_policy.dart';

class CacheFirstPolicyRegistry {
  const CacheFirstPolicyRegistry._();

  static const int defaultSchemaVersion = 1;
  static const int feedHomeSchemaVersion = 2;
  static const int shortHomeSchemaVersion = 2;
  static const int profilePostsSchemaVersion = 2;
  static const int notificationsInboxSchemaVersion = 2;
  static const int listingSnapshotSchemaVersion = 2;

  static const CacheFirstPolicy _timelineSnapshotPolicy = CacheFirstPolicy(
    snapshotTtl: Duration(minutes: 10),
    minLiveSyncInterval: Duration(seconds: 20),
    syncOnOpen: true,
    allowWarmLaunchFallback: true,
    persistWarmLaunchSnapshot: true,
    treatWarmLaunchAsStale: true,
    preservePreviousOnEmptyLive: true,
  );

  static const CacheFirstPolicy _listingSnapshotPolicy = CacheFirstPolicy(
    snapshotTtl: Duration(minutes: 20),
    minLiveSyncInterval: Duration(seconds: 30),
    syncOnOpen: true,
    allowWarmLaunchFallback: true,
    persistWarmLaunchSnapshot: true,
    treatWarmLaunchAsStale: true,
    preservePreviousOnEmptyLive: true,
  );

  static CacheFirstPolicy policyForSurface(String surfaceKey) {
    switch (surfaceKey.trim()) {
      case 'feed_home_snapshot':
        return _timelineSnapshotPolicy;
      case 'short_home_snapshot':
        return const CacheFirstPolicy(
          snapshotTtl: Duration(minutes: 12),
          minLiveSyncInterval: Duration(seconds: 20),
          syncOnOpen: true,
          allowWarmLaunchFallback: true,
          persistWarmLaunchSnapshot: true,
          treatWarmLaunchAsStale: true,
          preservePreviousOnEmptyLive: true,
        );
      case 'profile_posts_snapshot':
      case 'notifications_inbox_snapshot':
        return _timelineSnapshotPolicy;
      case 'market_home_snapshot':
      case 'market_search_snapshot':
      case 'jobs_home_snapshot':
      case 'jobs_search_snapshot':
      case 'scholarship_home_snapshot':
      case 'scholarship_search_snapshot':
      case 'answer_key_home_snapshot':
      case 'answer_key_search_snapshot':
      case 'tutoring_home_snapshot':
      case 'tutoring_search_snapshot':
      case 'practice_exam_home_snapshot':
      case 'practice_exam_search_snapshot':
      case 'workout_search_snapshot':
      case 'past_question_home_snapshot':
        return _listingSnapshotPolicy;
      default:
        return const CacheFirstPolicy();
    }
  }

  static int schemaVersionForSurface(String surfaceKey) {
    switch (surfaceKey.trim()) {
      case 'feed_home_snapshot':
        return feedHomeSchemaVersion;
      case 'short_home_snapshot':
        return shortHomeSchemaVersion;
      case 'profile_posts_snapshot':
        return profilePostsSchemaVersion;
      case 'notifications_inbox_snapshot':
        return notificationsInboxSchemaVersion;
      case 'market_home_snapshot':
      case 'market_search_snapshot':
      case 'jobs_home_snapshot':
      case 'jobs_search_snapshot':
      case 'scholarship_home_snapshot':
      case 'scholarship_search_snapshot':
      case 'answer_key_home_snapshot':
      case 'answer_key_search_snapshot':
      case 'tutoring_home_snapshot':
      case 'tutoring_search_snapshot':
      case 'practice_exam_home_snapshot':
      case 'practice_exam_search_snapshot':
      case 'workout_search_snapshot':
      case 'past_question_home_snapshot':
        return listingSnapshotSchemaVersion;
      default:
        return defaultSchemaVersion;
    }
  }
}
