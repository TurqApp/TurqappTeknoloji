class ReadBudgetRegistry {
  const ReadBudgetRegistry._();

  // Single source of truth for read, startup shard, and warmup budgets.

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

  static const int feedHomeInitialLimit = 40;
  static const int shortHomeInitialLimit = 20;
  static const int marketHomeInitialLimit = 40;
  static const int jobHomeInitialLimit = 40;

  static const int scholarshipHomeInitialLimit = 30;
  static const int scholarshipRepositoryLatestLimit = 40;
  static const int scholarshipProviderSeedLimit = 80;

  static const int practiceExamHomeInitialLimit = 30;
  static const int practiceExamTypeInitialLimit = 30;
  static const int testSharedPageLimit = 30;

  static const int storyInitialLimit = 30;
  static const int storyFullLimit = 100;

  static const int recommendedFollowingLimit = 100;
  static const int recommendedUsersWarmCount = 18;
  static const int recommendedUsersReadyCount = 60;
  static const int recommendedUsersFetchWarm = 80;
  static const int recommendedUsersInitialLimit = 200;
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

  static int feedInitialPoolLimit({required bool onWiFi}) =>
      feedHomeInitialLimit;

  static int shortInitialPoolLimit({required bool onWiFi}) => onWiFi ? 30 : 20;

  static int exploreInitialPoolLimit({required bool onWiFi}) =>
      onWiFi ? 30 : 20;

  static int profileInitialPoolLimit({required bool onWiFi}) =>
      onWiFi ? 30 : 20;

  static int storyInitialPoolLimit({required bool onWiFi}) => 10;

  static int shortStartupSnapshotLimit({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) {
    if (onWiFi) {
      return isFirstLaunch ? 6 : 8;
    }
    return isFirstLaunch ? 3 : 4;
  }

  static int shortStartupShardLimit({required bool onWiFi}) => onWiFi ? 6 : 4;

  static List<int> shortStartupAdditionalLimits({required bool onWiFi}) =>
      onWiFi ? const <int>[6, 8] : const <int>[3, 4];

  static int shortWarmTargetCount({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) =>
      shortStartupSnapshotLimit(
        onWiFi: onWiFi,
        isFirstLaunch: isFirstLaunch,
      );

  static int shortWarmMaxPages({required bool onWiFi}) => onWiFi ? 2 : 1;

  static int shortBackgroundWarmTargetCount = 8;
  static int shortBackgroundWarmMaxPages = 2;

  static int storyStartupWarmLimit({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) {
    if (onWiFi) {
      return isFirstLaunch ? 20 : 30;
    }
    return isFirstLaunch ? 10 : 16;
  }

  static int storyWarmReadyTarget({required bool onWiFi}) => onWiFi ? 30 : 18;

  static int startupListingWarmLimit({required bool onWiFi}) =>
      onWiFi ? 18 : 10;

  static int startupShortPrefetchDocLimit = 12;
  static int startupFeedPrefetchDocLimit = 15;

  static int startupUserMetaFeedTake({required bool onWiFi}) =>
      onWiFi ? 28 : 14;

  static int startupUserMetaStoryTake({required bool onWiFi}) =>
      onWiFi ? 18 : 10;

  static int startupUserMetaRecommendedTake({required bool onWiFi}) =>
      onWiFi ? 18 : 10;

  static int startupAvatarWarmCount({required bool onWiFi}) => onWiFi ? 36 : 12;

  static int startupProfileBucketTake({required bool onWiFi}) =>
      onWiFi ? 18 : 10;

  static int startupProfileUrlWarmCount({required bool onWiFi}) =>
      onWiFi ? 40 : 20;

  static int startupSliderWarmRemoteLimit({required bool onWiFi}) =>
      onWiFi ? 8 : 4;
}
