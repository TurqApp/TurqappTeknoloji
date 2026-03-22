part of 'deep_link_service.dart';

extension DeepLinkServiceLookupPart on DeepLinkService {
  Future<_PostLookupCache> _performGetPostLookup(String postId) async {
    _pruneStaleLookups();
    final cached = DeepLinkService._postLookupCache[postId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            DeepLinkService._lookupTtl) {
      return cached;
    }
    final doc =
        (await PostRepository.ensure().fetchPostCardsByIds([postId]))[postId];
    final lookup = _PostLookupCache(
      model: doc,
      cachedAt: DateTime.now(),
    );
    DeepLinkService._postLookupCache[postId] = lookup;
    return lookup;
  }

  Future<_JobLookupCache> _performGetJobLookup(String jobId) async {
    _pruneStaleLookups();
    final cached = DeepLinkService._jobLookupCache[jobId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            DeepLinkService._lookupTtl) {
      return cached;
    }
    final lookup = _JobLookupCache(
      model: await JobRepository.ensure().fetchById(
        jobId,
        preferCache: true,
      ),
      cachedAt: DateTime.now(),
    );
    DeepLinkService._jobLookupCache[jobId] = lookup;
    return lookup;
  }

  Future<_UserLookupCache> _performGetUserLookup(String userId) async {
    _pruneStaleLookups();
    final cached = DeepLinkService._userLookupCache[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            DeepLinkService._lookupTtl) {
      return cached;
    }
    final data = await _userSummaryResolver.resolve(
      userId,
      preferCache: true,
    );
    final lookup = _UserLookupCache(
      data: data,
      cachedAt: DateTime.now(),
    );
    DeepLinkService._userLookupCache[userId] = lookup;
    return lookup;
  }

  Future<_MarketLookupCache> _performGetMarketLookup(String itemId) async {
    _pruneStaleLookups();
    final cached = DeepLinkService._marketLookupCache[itemId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            DeepLinkService._lookupTtl) {
      return cached;
    }
    final lookup = _MarketLookupCache(
      model: await MarketRepository.ensure().fetchById(
        itemId,
        preferCache: true,
      ),
      cachedAt: DateTime.now(),
    );
    DeepLinkService._marketLookupCache[itemId] = lookup;
    return lookup;
  }

  Future<_StoryDocLookupCache> _performGetStoryDocLookup(String storyId) async {
    _pruneStaleLookups();
    final cached = DeepLinkService._storyDocLookupCache[storyId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            DeepLinkService._lookupTtl) {
      return cached;
    }
    final storyDoc =
        await StoryRepository.ensure().getStoryRaw(storyId, preferCache: true);
    final lookup = _StoryDocLookupCache(
      data: storyDoc,
      cachedAt: DateTime.now(),
    );
    DeepLinkService._storyDocLookupCache[storyId] = lookup;
    return lookup;
  }

  Future<List<StoryModel>> _performFetchStoriesByUserIndexSafe(
    String userId,
  ) async {
    _pruneStaleLookups();
    final cached = DeepLinkService._storyListLookupCache[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            DeepLinkService._lookupTtl) {
      return List<StoryModel>.from(cached.stories);
    }

    final stories = await StoryRepository.ensure().getStoriesForUser(
      userId,
      preferCache: true,
      includeDeleted: false,
    );
    DeepLinkService._storyListLookupCache[userId] = _StoryListLookupCache(
      stories: List<StoryModel>.from(stories),
      cachedAt: DateTime.now(),
    );
    return stories;
  }

  void _performPruneStaleLookups() {
    final now = DateTime.now();
    bool isStale(DateTime t) =>
        now.difference(t) > DeepLinkService._staleRetention;

    DeepLinkService._postLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    DeepLinkService._jobLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    DeepLinkService._marketLookupCache
        .removeWhere((_, v) => isStale(v.cachedAt));
    DeepLinkService._userLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    DeepLinkService._storyListLookupCache
        .removeWhere((_, v) => isStale(v.cachedAt));
    DeepLinkService._storyDocLookupCache
        .removeWhere((_, v) => isStale(v.cachedAt));
    _trimOldestIfNeeded();
  }

  void _performTrimOldestIfNeeded() {
    void trimMap<T>(
      Map<String, T> map,
      DateTime Function(T value) cachedAt,
    ) {
      if (map.length <= DeepLinkService._maxLookupEntries) return;
      final keysByAge = map.entries.toList()
        ..sort((a, b) => cachedAt(a.value).compareTo(cachedAt(b.value)));
      final removeCount = map.length - DeepLinkService._maxLookupEntries;
      for (var i = 0; i < removeCount; i++) {
        map.remove(keysByAge[i].key);
      }
    }

    trimMap<_PostLookupCache>(
        DeepLinkService._postLookupCache, (v) => v.cachedAt);
    trimMap<_JobLookupCache>(
        DeepLinkService._jobLookupCache, (v) => v.cachedAt);
    trimMap<_MarketLookupCache>(
      DeepLinkService._marketLookupCache,
      (v) => v.cachedAt,
    );
    trimMap<_UserLookupCache>(
        DeepLinkService._userLookupCache, (v) => v.cachedAt);
    trimMap<_StoryListLookupCache>(
      DeepLinkService._storyListLookupCache,
      (v) => v.cachedAt,
    );
    trimMap<_StoryDocLookupCache>(
      DeepLinkService._storyDocLookupCache,
      (v) => v.cachedAt,
    );
  }
}
