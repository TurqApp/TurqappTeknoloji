enum FeedHomePrimarySource {
  userFeedReferences,
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
    contractId: 'feed_home_primary_hybrid_v1',
    primarySource: FeedHomePrimarySource.userFeedReferences,
    supplementalSources: <FeedHomeSupplementalSource>[
      FeedHomeSupplementalSource.ownRecentPosts,
      FeedHomeSupplementalSource.celebrityRecentPosts,
      FeedHomeSupplementalSource.publicScheduledIzBirakPosts,
      FeedHomeSupplementalSource.globalBadgePosts,
    ],
    fallbackOrder: <FeedHomeFallbackPath>[
      FeedHomeFallbackPath.personalSnapshot,
      FeedHomeFallbackPath.legacyPage,
    ],
    usesPrimaryFeedPaging: true,
    primaryCollection: 'userFeeds',
    primaryItemsSubcollection: 'items',
    celebrityCollection: 'celebAccounts',
    requiredReferenceFields: <String>[
      'postId',
      'authorId',
      'timeStamp',
      'isCelebrity',
      'expiresAt',
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
