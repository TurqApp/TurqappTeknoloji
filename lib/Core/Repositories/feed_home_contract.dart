enum FeedHomePrimarySource {
  userFeedReferences,
  globalApprovedPosts,
}

enum FeedHomeSupplementalSource {
  ownRecentPosts,
  celebrityRecentPosts,
  publicScheduledIzBirakPosts,
  globalBadgePosts,
}

enum FeedHomeFallbackPath {
  personalSnapshot,
  legacyPage,
}

class FeedHomeContract {
  const FeedHomeContract({
    required this.contractId,
    required this.primarySource,
    required this.supplementalSources,
    required this.fallbackOrder,
    required this.usesPrimaryFeedPaging,
    required this.primaryCollection,
    required this.primaryItemsSubcollection,
    required this.celebrityCollection,
    required this.requiredReferenceFields,
  });

  static const FeedHomeContract primaryHybridV1 = FeedHomeContract(
    contractId: 'feed_home_primary_global_v2',
    primarySource: FeedHomePrimarySource.globalApprovedPosts,
    supplementalSources: <FeedHomeSupplementalSource>[
      FeedHomeSupplementalSource.ownRecentPosts,
      FeedHomeSupplementalSource.publicScheduledIzBirakPosts,
    ],
    fallbackOrder: <FeedHomeFallbackPath>[
      FeedHomeFallbackPath.personalSnapshot,
      FeedHomeFallbackPath.legacyPage,
    ],
    usesPrimaryFeedPaging: false,
    primaryCollection: 'Posts',
    primaryItemsSubcollection: '',
    celebrityCollection: 'celebAccounts',
    requiredReferenceFields: <String>[
      'timeStamp',
      'userID',
    ],
  );

  final String contractId;
  final FeedHomePrimarySource primarySource;
  final List<FeedHomeSupplementalSource> supplementalSources;
  final List<FeedHomeFallbackPath> fallbackOrder;
  final bool usesPrimaryFeedPaging;
  final String primaryCollection;
  final String primaryItemsSubcollection;
  final String celebrityCollection;
  final List<String> requiredReferenceFields;
}
