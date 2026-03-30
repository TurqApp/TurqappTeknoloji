import 'package:turqappv2/Core/Services/AppPolicy/surface_policy.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first_policy.dart';

class SurfacePolicyRegistry {
  const SurfacePolicyRegistry._();

  static const int defaultSchemaVersion = 1;
  static const int feedHomeSchemaVersion = 2;
  static const int shortHomeSchemaVersion = 2;
  static const int profilePostsSchemaVersion = 2;
  static const int notificationsInboxSchemaVersion = 2;
  static const int listingSnapshotSchemaVersion = 2;

  static const CacheFirstPolicy _timelineSnapshotCachePolicy = CacheFirstPolicy(
    snapshotTtl: Duration(minutes: 10),
    minLiveSyncInterval: Duration(seconds: 20),
    syncOnOpen: true,
    allowWarmLaunchFallback: true,
    persistWarmLaunchSnapshot: true,
    treatWarmLaunchAsStale: true,
    preservePreviousOnEmptyLive: true,
  );

  static const CacheFirstPolicy _shortTimelineSnapshotCachePolicy =
      CacheFirstPolicy(
    snapshotTtl: Duration(minutes: 12),
    minLiveSyncInterval: Duration(seconds: 20),
    syncOnOpen: true,
    allowWarmLaunchFallback: true,
    persistWarmLaunchSnapshot: true,
    treatWarmLaunchAsStale: true,
    preservePreviousOnEmptyLive: true,
  );

  static const CacheFirstPolicy _listingSnapshotCachePolicy = CacheFirstPolicy(
    snapshotTtl: Duration(minutes: 20),
    minLiveSyncInterval: Duration(seconds: 30),
    syncOnOpen: true,
    allowWarmLaunchFallback: true,
    persistWarmLaunchSnapshot: true,
    treatWarmLaunchAsStale: true,
    preservePreviousOnEmptyLive: true,
  );

  static const int savedPostRefsInitialLimit = 20;
  static const int savedMarketRefsInitialLimit = 20;
  static const int followRelationPreviewInitialLimit = 30;
  static const int notificationsInboxInitialLimit = 80;
  static const int notificationsDeltaFetchLimit = 40;
  static const int userReshareMapInitialLimit = 60;
  static const int reshareUserPreviewInitialLimit = 30;
  static const int reshareFeedWarmupInitialLimit = 60;
  static const int antremanCategoryPoolInitialLimit = 60;
  static const int antremanSavedQuestionInitialLimit = 60;

  static const int feedHomeInitialLimit = 32;
  static const int shortHomeInitialLimit = 18;
  static const int marketHomeInitialLimit = 40;
  static const int marketSearchInitialLimit = 40;
  static const int jobHomeInitialLimit = 40;
  static const int jobSearchInitialLimit = 40;
  static const int scholarshipHomeInitialLimit = 30;
  static const int scholarshipRepositoryLatestLimit = 40;
  static const int scholarshipSearchInitialLimit = 40;
  static const int scholarshipProviderSeedLimit = 80;
  static const int practiceExamHomeInitialLimit = 30;
  static const int practiceExamSearchInitialLimit = 40;
  static const int practiceExamTypeInitialLimit = 30;
  static const int testSharedPageLimit = 30;
  static const int answerKeyHomeInitialLimit = 30;
  static const int answerKeySearchInitialLimit = 40;
  static const int tutoringHomeInitialLimit = 30;
  static const int tutoringSearchInitialLimit = 40;
  static const int pastQuestionSearchInitialLimit = 40;
  static const int questionBankSearchInitialLimit = 40;

  static const int storyInitialLimit = 30;
  static const int storyFullLimit = 100;

  static const int recommendedFollowingLimit = 100;
  static const int recommendedUsersWarmCount = 18;
  static const int recommendedUsersReadyCount = 60;
  static const int recommendedUsersFetchWarm = 80;
  static const int recommendedUsersInitialLimit = 250;
  static const int recommendedUsersFullLimit = 500;

  static const int feedReadyForNavCount = 3;
  static const int storyReadyForNavCount = 1;
  static const int shortReadyForNavCount = 1;

  static const int marketStartupShardLimit = 8;
  static const int jobStartupShardLimit = 8;
  static const int profileStartupShardLimit = 6;
  static const int exploreStartupTagsShardLimit = 18;
  static const int exploreStartupPostsShardLimit = 8;
  static const int exploreStartupShardLimit = 26;

  static const int exploreTrendingTagsLimit = 30;
  static const int explorePostsPageLimit = 20;
  static const int exploreVideoPageLimit = 30;
  static const int explorePhotoPageLimit = 20;
  static const int exploreFloodPageLimit = 60;
  static const int explorePostsBootstrapTargetBatch = 12;
  static const int explorePostsTargetBatch = 24;
  static const int explorePostsBootstrapMaxPages = 4;
  static const int explorePostsMaxPages = 10;
  static const int exploreVideoTargetBatch = 24;
  static const int exploreVideoMaxPages = 10;
  static const int explorePhotoTargetBatch = 30;
  static const int explorePhotoMaxPages = 5;

  static const int mobileWarmWindow = 16;
  static const int mobileNextWindow = 8;
  static const int minGlobalCachedVideos = 40;
  static const int mobileInitialSegments = 2;
  static const int mobileAheadSegments = 3;

  static const int startupListingWarmLimitOnWiFi = 14;
  static const int startupListingWarmLimitOnCellular = 8;
  static const int startupShortPrefetchDocLimit = 8;
  static const int startupFeedPrefetchDocLimit = 12;

  static const int startupUserMetaFeedTakeOnWiFi = 24;
  static const int startupUserMetaFeedTakeOnCellular = 12;
  static const int startupUserMetaStoryTakeOnWiFi = 16;
  static const int startupUserMetaStoryTakeOnCellular = 8;
  static const int startupUserMetaRecommendedTakeOnWiFi = 16;
  static const int startupUserMetaRecommendedTakeOnCellular = 8;
  static const int startupAvatarWarmCountOnWiFi = 24;
  static const int startupAvatarWarmCountOnCellular = 10;
  static const int startupProfileBucketTakeOnWiFi = 14;
  static const int startupProfileBucketTakeOnCellular = 8;
  static const int startupProfileUrlWarmCountOnWiFi = 28;
  static const int startupProfileUrlWarmCountOnCellular = 14;
  static const int startupSliderWarmRemoteLimitOnWiFi = 6;
  static const int startupSliderWarmRemoteLimitOnCellular = 3;

  static const SurfacePolicy defaultSurface = SurfacePolicy();

  static const SurfacePolicy feedHomeSurface = SurfacePolicy(
    schemaVersion: feedHomeSchemaVersion,
    cachePolicy: _timelineSnapshotCachePolicy,
    initialLimit: feedHomeInitialLimit,
    readyForNavCount: feedReadyForNavCount,
    initialPoolLimit: AdaptiveIntPolicy.uniform(feedHomeInitialLimit),
    startupPrefetchDocLimit: startupFeedPrefetchDocLimit,
    bootstrapOnCellularWhenHasLocalContent: true,
  );

  static const SurfacePolicy shortHomeSurface = SurfacePolicy(
    schemaVersion: shortHomeSchemaVersion,
    cachePolicy: _shortTimelineSnapshotCachePolicy,
    initialLimit: shortHomeInitialLimit,
    readyForNavCount: shortReadyForNavCount,
    initialPoolLimit: AdaptiveIntPolicy(
      onWiFi: 24,
      onCellular: 18,
    ),
    startupShardLimit: AdaptiveIntPolicy(
      onWiFi: 5,
      onCellular: 4,
    ),
    startupSnapshotLimit: LaunchAwareIntPolicy(
      wifiFirstLaunch: 5,
      wifiWarmLaunch: 6,
      cellularFirstLaunch: 3,
      cellularWarmLaunch: 4,
    ),
    backgroundWarmTargetCount: 6,
    backgroundWarmMaxPages: 2,
    startupPrefetchDocLimit: startupShortPrefetchDocLimit,
  );

  static const SurfacePolicy exploreSurface = SurfacePolicy(
    initialPoolLimit: AdaptiveIntPolicy(
      onWiFi: 30,
      onCellular: 20,
    ),
    startupShardLimit: AdaptiveIntPolicy.uniform(exploreStartupShardLimit),
  );

  static const SurfacePolicy storySurface = SurfacePolicy(
    initialLimit: storyInitialLimit,
    fullLimit: storyFullLimit,
    readyForNavCount: storyReadyForNavCount,
    initialPoolLimit: AdaptiveIntPolicy.uniform(10),
    startupWarmLimit: LaunchAwareIntPolicy(
      wifiFirstLaunch: 16,
      wifiWarmLaunch: 24,
      cellularFirstLaunch: 8,
      cellularWarmLaunch: 12,
    ),
    warmReadyTarget: AdaptiveIntPolicy(
      onWiFi: 24,
      onCellular: 14,
    ),
  );

  static const SurfacePolicy profilePostsSurface = SurfacePolicy(
    schemaVersion: profilePostsSchemaVersion,
    cachePolicy: _timelineSnapshotCachePolicy,
    startupShardLimit: AdaptiveIntPolicy.uniform(profileStartupShardLimit),
    initialPoolLimit: AdaptiveIntPolicy(
      onWiFi: 30,
      onCellular: 20,
    ),
  );

  static const SurfacePolicy notificationsInboxSurface = SurfacePolicy(
    schemaVersion: notificationsInboxSchemaVersion,
    cachePolicy: _timelineSnapshotCachePolicy,
    initialLimit: notificationsInboxInitialLimit,
  );

  static const SurfacePolicy listingSnapshotSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
  );

  static const SurfacePolicy marketHomeSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: marketHomeInitialLimit,
  );

  static const SurfacePolicy marketSearchSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: marketSearchInitialLimit,
  );

  static const SurfacePolicy jobHomeSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: jobHomeInitialLimit,
  );

  static const SurfacePolicy jobSearchSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: jobSearchInitialLimit,
  );

  static const SurfacePolicy scholarshipHomeSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: scholarshipHomeInitialLimit,
  );

  static const SurfacePolicy scholarshipSearchSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: scholarshipSearchInitialLimit,
  );

  static const SurfacePolicy practiceExamHomeSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: practiceExamHomeInitialLimit,
  );

  static const SurfacePolicy practiceExamSearchSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: practiceExamSearchInitialLimit,
  );

  static const SurfacePolicy tutoringHomeSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: tutoringHomeInitialLimit,
  );

  static const SurfacePolicy tutoringSearchSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: tutoringSearchInitialLimit,
  );

  static const SurfacePolicy answerKeyHomeSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: answerKeyHomeInitialLimit,
  );

  static const SurfacePolicy answerKeySearchSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: answerKeySearchInitialLimit,
  );

  static const SurfacePolicy pastQuestionSearchSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: pastQuestionSearchInitialLimit,
  );

  static const SurfacePolicy questionBankSearchSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: questionBankSearchInitialLimit,
  );

  static const SurfacePolicy testSharedSurface = SurfacePolicy(
    schemaVersion: listingSnapshotSchemaVersion,
    cachePolicy: _listingSnapshotCachePolicy,
    initialLimit: testSharedPageLimit,
    pageLimit: testSharedPageLimit,
  );

  static SurfacePolicy policyForContentScreenName(String screenName) {
    switch (screenName.trim()) {
      case 'feed':
        return feedHomeSurface;
      case 'shorts':
        return shortHomeSurface;
      case 'explore':
        return exploreSurface;
      case 'story':
        return storySurface;
      case 'profile':
        return profilePostsSurface;
      default:
        return defaultSurface;
    }
  }

  static SurfacePolicy policyForSnapshotSurface(String surfaceKey) {
    switch (surfaceKey.trim()) {
      case 'feed_home_snapshot':
        return feedHomeSurface;
      case 'short_home_snapshot':
        return shortHomeSurface;
      case 'profile_posts_snapshot':
        return profilePostsSurface;
      case 'notifications_inbox_snapshot':
        return notificationsInboxSurface;
      case 'market_home_snapshot':
        return marketHomeSurface;
      case 'market_search_snapshot':
        return marketSearchSurface;
      case 'jobs_home_snapshot':
        return jobHomeSurface;
      case 'jobs_search_snapshot':
        return jobSearchSurface;
      case 'scholarship_home_snapshot':
        return scholarshipHomeSurface;
      case 'scholarship_search_snapshot':
        return scholarshipSearchSurface;
      case 'practice_exam_home_snapshot':
        return practiceExamHomeSurface;
      case 'practice_exam_search_snapshot':
        return practiceExamSearchSurface;
      case 'tutoring_home_snapshot':
        return tutoringHomeSurface;
      case 'tutoring_search_snapshot':
        return tutoringSearchSurface;
      case 'answer_key_home_snapshot':
        return answerKeyHomeSurface;
      case 'answer_key_search_snapshot':
        return answerKeySearchSurface;
      case 'past_question_home_snapshot':
        return pastQuestionSearchSurface;
      case 'test_shared_snapshot':
        return testSharedSurface;
      case 'market_owner_snapshot':
      case 'jobs_owner_snapshot':
      case 'answer_key_owner_snapshot':
      case 'answer_key_type_snapshot':
      case 'optical_form_answered_snapshot':
      case 'optical_form_owner_snapshot':
      case 'test_answered_snapshot':
      case 'test_favorites_snapshot':
      case 'test_home_snapshot':
      case 'test_type_snapshot':
      case 'test_owner_snapshot':
      case 'tutoring_owner_snapshot':
      case 'practice_exam_owner_snapshot':
      case 'practice_exam_answered_snapshot':
      case 'practice_exam_type_snapshot':
      case 'workout_search_snapshot':
        return listingSnapshotSurface;
      default:
        return defaultSurface;
    }
  }

  static int startupListingWarmLimit({required bool onWiFi}) => onWiFi
      ? startupListingWarmLimitOnWiFi
      : startupListingWarmLimitOnCellular;

  static int startupUserMetaFeedTake({required bool onWiFi}) => onWiFi
      ? startupUserMetaFeedTakeOnWiFi
      : startupUserMetaFeedTakeOnCellular;

  static int startupUserMetaStoryTake({required bool onWiFi}) => onWiFi
      ? startupUserMetaStoryTakeOnWiFi
      : startupUserMetaStoryTakeOnCellular;

  static int startupUserMetaRecommendedTake({required bool onWiFi}) => onWiFi
      ? startupUserMetaRecommendedTakeOnWiFi
      : startupUserMetaRecommendedTakeOnCellular;

  static int startupAvatarWarmCount({required bool onWiFi}) =>
      onWiFi ? startupAvatarWarmCountOnWiFi : startupAvatarWarmCountOnCellular;

  static int startupProfileBucketTake({required bool onWiFi}) => onWiFi
      ? startupProfileBucketTakeOnWiFi
      : startupProfileBucketTakeOnCellular;

  static int startupProfileUrlWarmCount({required bool onWiFi}) => onWiFi
      ? startupProfileUrlWarmCountOnWiFi
      : startupProfileUrlWarmCountOnCellular;

  static int startupSliderWarmRemoteLimit({required bool onWiFi}) => onWiFi
      ? startupSliderWarmRemoteLimitOnWiFi
      : startupSliderWarmRemoteLimitOnCellular;
}
