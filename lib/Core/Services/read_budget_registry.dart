import 'package:turqappv2/Core/Services/AppPolicy/surface_policy_override_service.dart';
import 'package:turqappv2/Core/Services/AppPolicy/surface_policy_registry.dart';

class ReadBudgetRegistry {
  const ReadBudgetRegistry._();

  // Backward-compatible facade over SurfacePolicyRegistry.

  static const int savedPostRefsInitialLimit =
      SurfacePolicyRegistry.savedPostRefsInitialLimit;
  static const int savedMarketRefsInitialLimit =
      SurfacePolicyRegistry.savedMarketRefsInitialLimit;
  static const int followRelationPreviewInitialLimit =
      SurfacePolicyRegistry.followRelationPreviewInitialLimit;
  static const int notificationsInboxInitialLimit =
      SurfacePolicyRegistry.notificationsInboxInitialLimit;
  static const int notificationsDeltaFetchLimit =
      SurfacePolicyRegistry.notificationsDeltaFetchLimit;
  static const int userReshareMapInitialLimit =
      SurfacePolicyRegistry.userReshareMapInitialLimit;
  static const int reshareUserPreviewInitialLimit =
      SurfacePolicyRegistry.reshareUserPreviewInitialLimit;
  static const int reshareFeedWarmupInitialLimit =
      SurfacePolicyRegistry.reshareFeedWarmupInitialLimit;
  static const int reshareScanPostLimit =
      SurfacePolicyRegistry.reshareScanPostLimit;
  static const int reshareTargetPostLimit =
      SurfacePolicyRegistry.reshareTargetPostLimit;
  static const int antremanCategoryPoolInitialLimit =
      SurfacePolicyRegistry.antremanCategoryPoolInitialLimit;
  static const int antremanSavedQuestionInitialLimit =
      SurfacePolicyRegistry.antremanSavedQuestionInitialLimit;

  static const int feedHomeInitialLimit =
      SurfacePolicyRegistry.feedHomeInitialLimit;
  static const int feedLivePageLimit = SurfacePolicyRegistry.feedLivePageLimit;
  static const int feedBufferedFetchLimit =
      SurfacePolicyRegistry.feedBufferedFetchLimit;
  static const int feedPersistSnapshotLimit =
      SurfacePolicyRegistry.feedPersistSnapshotLimit;
  static const int feedVisiblePublicFallbackMinLimit =
      SurfacePolicyRegistry.feedVisiblePublicFallbackMinLimit;
  static const int feedGlobalBadgeMinLimit =
      SurfacePolicyRegistry.feedGlobalBadgeMinLimit;
  static const int feedShuffleInitialFetchSize =
      SurfacePolicyRegistry.feedShuffleInitialFetchSize;
  static const int feedShuffleBackgroundFetchSize =
      SurfacePolicyRegistry.feedShuffleBackgroundFetchSize;
  static const int shortHomeInitialLimit =
      SurfacePolicyRegistry.shortHomeInitialLimit;
  static const int shortRandomReadyPoolLimit =
      SurfacePolicyRegistry.shortRandomReadyPoolLimit;
  static const int marketHomeInitialLimit =
      SurfacePolicyRegistry.marketHomeInitialLimit;
  static const int marketSearchInitialLimit =
      SurfacePolicyRegistry.marketSearchInitialLimit;
  static const int marketOwnerInitialLimit =
      SurfacePolicyRegistry.marketOwnerInitialLimit;
  static const int jobHomeInitialLimit =
      SurfacePolicyRegistry.jobHomeInitialLimit;
  static const int jobSearchInitialLimit =
      SurfacePolicyRegistry.jobSearchInitialLimit;
  static const int jobOwnerInitialLimit =
      SurfacePolicyRegistry.jobOwnerInitialLimit;
  static const int jobRelatedFetchLimit =
      SurfacePolicyRegistry.jobRelatedFetchLimit;
  static const int jobRelatedVisibleLimit =
      SurfacePolicyRegistry.jobRelatedVisibleLimit;
  static const int scholarshipHomeInitialLimit =
      SurfacePolicyRegistry.scholarshipHomeInitialLimit;
  static const int scholarshipRepositoryLatestLimit =
      SurfacePolicyRegistry.scholarshipRepositoryLatestLimit;
  static const int scholarshipSearchInitialLimit =
      SurfacePolicyRegistry.scholarshipSearchInitialLimit;
  static const int scholarshipProviderSeedLimit =
      SurfacePolicyRegistry.scholarshipProviderSeedLimit;
  static const int scholarshipMineInitialLimit =
      SurfacePolicyRegistry.scholarshipMineInitialLimit;
  static const int scholarshipAppliedInitialLimit =
      SurfacePolicyRegistry.scholarshipAppliedInitialLimit;
  static const int scholarshipSavedInitialLimit =
      SurfacePolicyRegistry.scholarshipSavedInitialLimit;
  static const int scholarshipPersonalizedInitialLimit =
      SurfacePolicyRegistry.scholarshipPersonalizedInitialLimit;
  static const int scholarshipPersonalizedShowcaseLimit =
      SurfacePolicyRegistry.scholarshipPersonalizedShowcaseLimit;
  static const int practiceExamHomeInitialLimit =
      SurfacePolicyRegistry.practiceExamHomeInitialLimit;
  static const int practiceExamSearchInitialLimit =
      SurfacePolicyRegistry.practiceExamSearchInitialLimit;
  static const int practiceExamTypeInitialLimit =
      SurfacePolicyRegistry.practiceExamTypeInitialLimit;
  static const int practiceExamAnsweredInitialLimit =
      SurfacePolicyRegistry.practiceExamAnsweredInitialLimit;
  static const int testSharedPageLimit =
      SurfacePolicyRegistry.testSharedPageLimit;
  static const int testAnsweredInitialLimit =
      SurfacePolicyRegistry.testAnsweredInitialLimit;
  static const int testFavoritesInitialLimit =
      SurfacePolicyRegistry.testFavoritesInitialLimit;
  static const int answerKeyHomeInitialLimit =
      SurfacePolicyRegistry.answerKeyHomeInitialLimit;
  static const int answerKeySearchInitialLimit =
      SurfacePolicyRegistry.answerKeySearchInitialLimit;
  static const int opticalFormAnsweredInitialLimit =
      SurfacePolicyRegistry.opticalFormAnsweredInitialLimit;
  static const int tutoringHomeInitialLimit =
      SurfacePolicyRegistry.tutoringHomeInitialLimit;
  static const int tutoringSearchInitialLimit =
      SurfacePolicyRegistry.tutoringSearchInitialLimit;
  static const int tutoringSearchBootstrapLimit =
      SurfacePolicyRegistry.tutoringSearchBootstrapLimit;
  static const int tutoringLocationBasedFetchLimit =
      SurfacePolicyRegistry.tutoringLocationBasedFetchLimit;
  static const int pastQuestionSearchInitialLimit =
      SurfacePolicyRegistry.pastQuestionSearchInitialLimit;
  static const int questionBankSearchInitialLimit =
      SurfacePolicyRegistry.questionBankSearchInitialLimit;
  static const int marketRelatedFetchLimit =
      SurfacePolicyRegistry.marketRelatedFetchLimit;
  static const int marketRelatedVisibleLimit =
      SurfacePolicyRegistry.marketRelatedVisibleLimit;
  static const int topTagsFeedPostLimit =
      SurfacePolicyRegistry.topTagsFeedPostLimit;
  static const int topTagsTrendingResultLimit =
      SurfacePolicyRegistry.topTagsTrendingResultLimit;
  static const int topTagsRepositoryFetchLimit =
      SurfacePolicyRegistry.topTagsRepositoryFetchLimit;
  static const int postLikeListingPageLimit =
      SurfacePolicyRegistry.postLikeListingPageLimit;
  static const int explorePrefetchDocLimit =
      SurfacePolicyRegistry.explorePrefetchDocLimit;

  static const int storyInitialLimit = SurfacePolicyRegistry.storyInitialLimit;
  static const int storyFullLimit = SurfacePolicyRegistry.storyFullLimit;

  static const int recommendedFollowingLimit =
      SurfacePolicyRegistry.recommendedFollowingLimit;
  static const int recommendedUsersWarmCount =
      SurfacePolicyRegistry.recommendedUsersWarmCount;
  static const int recommendedUsersReadyCount =
      SurfacePolicyRegistry.recommendedUsersReadyCount;
  static const int recommendedUsersFetchWarm =
      SurfacePolicyRegistry.recommendedUsersFetchWarm;
  static const int recommendedUsersInitialLimit =
      SurfacePolicyRegistry.recommendedUsersInitialLimit;
  static const int recommendedUsersFullLimit =
      SurfacePolicyRegistry.recommendedUsersFullLimit;

  static const int feedReadyForNavCount =
      SurfacePolicyRegistry.feedReadyForNavCount;
  static const int storyReadyForNavCount =
      SurfacePolicyRegistry.storyReadyForNavCount;
  static const int shortReadyForNavCount =
      SurfacePolicyRegistry.shortReadyForNavCount;

  static const int marketStartupShardLimit =
      SurfacePolicyRegistry.marketStartupShardLimit;
  static const int jobStartupShardLimit =
      SurfacePolicyRegistry.jobStartupShardLimit;
  static const int profileStartupShardLimit =
      SurfacePolicyRegistry.profileStartupShardLimit;
  static const int exploreStartupTagsShardLimit =
      SurfacePolicyRegistry.exploreStartupTagsShardLimit;
  static const int exploreStartupPostsShardLimit =
      SurfacePolicyRegistry.exploreStartupPostsShardLimit;
  static const int exploreStartupShardLimit =
      SurfacePolicyRegistry.exploreStartupShardLimit;

  static const int exploreTrendingTagsLimit =
      SurfacePolicyRegistry.exploreTrendingTagsLimit;
  static const int explorePostsPageLimit =
      SurfacePolicyRegistry.explorePostsPageLimit;
  static const int exploreVideoPageLimit =
      SurfacePolicyRegistry.exploreVideoPageLimit;
  static const int explorePhotoPageLimit =
      SurfacePolicyRegistry.explorePhotoPageLimit;
  static const int exploreFloodPageLimit =
      SurfacePolicyRegistry.exploreFloodPageLimit;
  static const int explorePostsBootstrapTargetBatch =
      SurfacePolicyRegistry.explorePostsBootstrapTargetBatch;
  static const int explorePostsTargetBatch =
      SurfacePolicyRegistry.explorePostsTargetBatch;
  static const int explorePostsBootstrapMaxPages =
      SurfacePolicyRegistry.explorePostsBootstrapMaxPages;
  static const int explorePostsMaxPages =
      SurfacePolicyRegistry.explorePostsMaxPages;
  static const int exploreVideoTargetBatch =
      SurfacePolicyRegistry.exploreVideoTargetBatch;
  static const int exploreVideoMaxPages =
      SurfacePolicyRegistry.exploreVideoMaxPages;
  static const int explorePhotoTargetBatch =
      SurfacePolicyRegistry.explorePhotoTargetBatch;
  static const int explorePhotoMaxPages =
      SurfacePolicyRegistry.explorePhotoMaxPages;

  static int _readOverride(String key, int fallback) =>
      maybeFindSurfacePolicyOverrideService()?.readInt(key, fallback) ??
      fallback;

  static int _resolveConfiguredValue(
    int value, {
    required int defaultValue,
    required int configuredValue,
  }) {
    final normalized = value < 1 ? configuredValue : value;
    return normalized == defaultValue ? configuredValue : normalized;
  }

  static int get feedHomeInitialLimitValue => _readOverride(
        SurfacePolicyOverrideKeys.feedHomeInitialLimit,
        feedHomeInitialLimit,
      );

  static int get shortHomeInitialLimitValue => _readOverride(
        SurfacePolicyOverrideKeys.shortHomeInitialLimit,
        shortHomeInitialLimit,
      );

  static int get recommendedUsersInitialLimitValue => _readOverride(
        SurfacePolicyOverrideKeys.recommendedUsersInitialLimit,
        recommendedUsersInitialLimit,
      );

  static int get marketOwnerInitialLimitValue => _readOverride(
        SurfacePolicyOverrideKeys.marketOwnerInitialLimit,
        marketOwnerInitialLimit,
      );

  static int get jobOwnerInitialLimitValue => _readOverride(
        SurfacePolicyOverrideKeys.jobOwnerInitialLimit,
        jobOwnerInitialLimit,
      );

  static int get testAnsweredInitialLimitValue => _readOverride(
        SurfacePolicyOverrideKeys.testAnsweredInitialLimit,
        testAnsweredInitialLimit,
      );

  static int get testFavoritesInitialLimitValue => _readOverride(
        SurfacePolicyOverrideKeys.testFavoritesInitialLimit,
        testFavoritesInitialLimit,
      );

  static int get practiceExamAnsweredInitialLimitValue => _readOverride(
        SurfacePolicyOverrideKeys.practiceExamAnsweredInitialLimit,
        practiceExamAnsweredInitialLimit,
      );

  static int get opticalFormAnsweredInitialLimitValue => _readOverride(
        SurfacePolicyOverrideKeys.opticalFormAnsweredInitialLimit,
        opticalFormAnsweredInitialLimit,
      );

  static int get mobileWarmWindow => _readOverride(
        SurfacePolicyOverrideKeys.mobileWarmWindow,
        SurfacePolicyRegistry.mobileWarmWindow,
      );

  static int get mobileNextWindow => _readOverride(
        SurfacePolicyOverrideKeys.mobileNextWindow,
        SurfacePolicyRegistry.mobileNextWindow,
      );

  static int get minGlobalCachedVideos => _readOverride(
        SurfacePolicyOverrideKeys.minGlobalCachedVideos,
        SurfacePolicyRegistry.minGlobalCachedVideos,
      );

  static int get mobileInitialSegments => _readOverride(
        SurfacePolicyOverrideKeys.mobileInitialSegments,
        SurfacePolicyRegistry.mobileInitialSegments,
      );

  static int get mobileAheadSegments => _readOverride(
        SurfacePolicyOverrideKeys.mobileAheadSegments,
        SurfacePolicyRegistry.mobileAheadSegments,
      );

  static const int segmentPrefetchBreadthCount =
      SurfacePolicyRegistry.segmentPrefetchBreadthCount;

  static const int segmentPrefetchDepthCount =
      SurfacePolicyRegistry.segmentPrefetchDepthCount;

  static const int segmentPrefetchMaxConcurrent =
      SurfacePolicyRegistry.segmentPrefetchMaxConcurrent;

  static const int segmentCacheSoftLimitMb =
      SurfacePolicyRegistry.segmentCacheSoftLimitMb;

  static const int segmentCacheHardLimitMb =
      SurfacePolicyRegistry.segmentCacheHardLimitMb;

  static const int segmentCacheRecentProtectCount =
      SurfacePolicyRegistry.segmentCacheRecentProtectCount;

  static const int profilePostsInitialLimit =
      SurfacePolicyRegistry.profilePostsInitialLimit;

  static int resolveFeedHomeInitialLimit(int value) => _resolveConfiguredValue(
        value,
        defaultValue: feedHomeInitialLimit,
        configuredValue: feedHomeInitialLimitValue,
      );

  static int resolveShortHomeInitialLimit(int value) => _resolveConfiguredValue(
        value,
        defaultValue: shortHomeInitialLimit,
        configuredValue: shortHomeInitialLimitValue,
      );

  static int resolveRecommendedUsersInitialLimit(int value) =>
      _resolveConfiguredValue(
        value,
        defaultValue: recommendedUsersInitialLimit,
        configuredValue: recommendedUsersInitialLimitValue,
      );

  static int resolveMarketOwnerInitialLimit(int value) =>
      _resolveConfiguredValue(
        value,
        defaultValue: marketOwnerInitialLimit,
        configuredValue: marketOwnerInitialLimitValue,
      );

  static int resolveJobOwnerInitialLimit(int value) => _resolveConfiguredValue(
        value,
        defaultValue: jobOwnerInitialLimit,
        configuredValue: jobOwnerInitialLimitValue,
      );

  static int resolveTestAnsweredInitialLimit(int value) =>
      _resolveConfiguredValue(
        value,
        defaultValue: testAnsweredInitialLimit,
        configuredValue: testAnsweredInitialLimitValue,
      );

  static int resolveTestFavoritesInitialLimit(int value) =>
      _resolveConfiguredValue(
        value,
        defaultValue: testFavoritesInitialLimit,
        configuredValue: testFavoritesInitialLimitValue,
      );

  static int resolvePracticeExamAnsweredInitialLimit(int value) =>
      _resolveConfiguredValue(
        value,
        defaultValue: practiceExamAnsweredInitialLimit,
        configuredValue: practiceExamAnsweredInitialLimitValue,
      );

  static int resolveOpticalFormAnsweredInitialLimit(int value) =>
      _resolveConfiguredValue(
        value,
        defaultValue: opticalFormAnsweredInitialLimit,
        configuredValue: opticalFormAnsweredInitialLimitValue,
      );

  static int feedInitialPoolLimit({required bool onWiFi}) =>
      feedHomeInitialLimitValue;

  static int shortInitialPoolLimit({required bool onWiFi}) =>
      SurfacePolicyRegistry.shortHomeSurface.initialPoolLimitFor(
        onWiFi: onWiFi,
      );

  static int exploreInitialPoolLimit({required bool onWiFi}) =>
      SurfacePolicyRegistry.exploreSurface.initialPoolLimitFor(
        onWiFi: onWiFi,
      );

  static int profileInitialPoolLimit({required bool onWiFi}) =>
      SurfacePolicyRegistry.profilePostsSurface.initialPoolLimitFor(
        onWiFi: onWiFi,
      );

  static int storyInitialPoolLimit({required bool onWiFi}) =>
      SurfacePolicyRegistry.storySurface.initialPoolLimitFor(
        onWiFi: onWiFi,
      );

  static int shortStartupSnapshotLimit({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) =>
      SurfacePolicyRegistry.shortHomeSurface.startupSnapshotLimitFor(
        onWiFi: onWiFi,
        isFirstLaunch: isFirstLaunch,
      );

  static int shortStartupShardLimit({required bool onWiFi}) =>
      SurfacePolicyRegistry.shortHomeSurface.startupShardLimitFor(
        onWiFi: onWiFi,
      );

  static List<int> shortStartupAdditionalLimits({required bool onWiFi}) =>
      SurfacePolicyRegistry.shortHomeSurface.startupSnapshotAdditionalLimits(
        onWiFi: onWiFi,
      );

  static int shortWarmTargetCount({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) =>
      SurfacePolicyRegistry.shortHomeSurface.warmTargetCountFor(
        onWiFi: onWiFi,
        isFirstLaunch: isFirstLaunch,
      );

  static int shortWarmMaxPages({required bool onWiFi}) => onWiFi ? 2 : 1;

  static int get shortBackgroundWarmTargetCount =>
      SurfacePolicyRegistry.shortHomeSurface.backgroundWarmTargetCount ?? 0;

  static int get shortBackgroundWarmMaxPages =>
      SurfacePolicyRegistry.shortHomeSurface.backgroundWarmMaxPages ?? 0;

  static int storyStartupWarmLimit({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) =>
      SurfacePolicyRegistry.storySurface.startupWarmLimitFor(
        onWiFi: onWiFi,
        isFirstLaunch: isFirstLaunch,
      );

  static int storyWarmReadyTarget({required bool onWiFi}) =>
      SurfacePolicyRegistry.storySurface.warmReadyTargetFor(
        onWiFi: onWiFi,
      );

  static int startupListingWarmLimit({required bool onWiFi}) => _readOverride(
        onWiFi
            ? SurfacePolicyOverrideKeys.startupListingWarmLimitOnWiFi
            : SurfacePolicyOverrideKeys.startupListingWarmLimitOnCellular,
        SurfacePolicyRegistry.startupListingWarmLimit(onWiFi: onWiFi),
      );

  static int get startupShortPrefetchDocLimit => _readOverride(
        SurfacePolicyOverrideKeys.startupShortPrefetchDocLimit,
        SurfacePolicyRegistry.startupShortPrefetchDocLimit,
      );

  static int get startupFeedPrefetchDocLimit => _readOverride(
        SurfacePolicyOverrideKeys.startupFeedPrefetchDocLimit,
        SurfacePolicyRegistry.startupFeedPrefetchDocLimit,
      );

  static int get segmentCacheSoftLimitBytes =>
      segmentCacheSoftLimitMb * 1024 * 1024;

  static int get segmentCacheHardLimitBytes =>
      segmentCacheHardLimitMb * 1024 * 1024;

  static int startupUserMetaFeedTake({required bool onWiFi}) =>
      SurfacePolicyRegistry.startupUserMetaFeedTake(onWiFi: onWiFi);

  static int startupUserMetaStoryTake({required bool onWiFi}) =>
      SurfacePolicyRegistry.startupUserMetaStoryTake(onWiFi: onWiFi);

  static int startupUserMetaRecommendedTake({required bool onWiFi}) =>
      SurfacePolicyRegistry.startupUserMetaRecommendedTake(onWiFi: onWiFi);

  static int startupAvatarWarmCount({required bool onWiFi}) =>
      SurfacePolicyRegistry.startupAvatarWarmCount(onWiFi: onWiFi);

  static int startupProfileBucketTake({required bool onWiFi}) =>
      SurfacePolicyRegistry.startupProfileBucketTake(onWiFi: onWiFi);

  static int startupProfileUrlWarmCount({required bool onWiFi}) =>
      SurfacePolicyRegistry.startupProfileUrlWarmCount(onWiFi: onWiFi);

  static int startupSliderWarmRemoteLimit({required bool onWiFi}) =>
      SurfacePolicyRegistry.startupSliderWarmRemoteLimit(onWiFi: onWiFi);
}
