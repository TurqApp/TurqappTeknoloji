part of 'deep_link_service.dart';

extension DeepLinkServiceLookupPart on DeepLinkService {
  Future<_PostLookupCache> _performGetPostLookup(String postId) async {
    _pruneStaleLookups();
    final cached = _deepLinkPostLookupCache[postId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _deepLinkLookupTtl) {
      return cached;
    }
    final doc =
        (await PostRepository.ensure().fetchPostCardsByIds([postId]))[postId];
    final lookup = _PostLookupCache(
      model: doc,
      cachedAt: DateTime.now(),
    );
    _deepLinkPostLookupCache[postId] = lookup;
    return lookup;
  }

  Future<_JobLookupCache> _performGetJobLookup(String jobId) async {
    _pruneStaleLookups();
    final cached = _deepLinkJobLookupCache[jobId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _deepLinkLookupTtl) {
      return cached;
    }
    final lookup = _JobLookupCache(
      model: await ensureJobRepository().fetchById(
        jobId,
        preferCache: true,
      ),
      cachedAt: DateTime.now(),
    );
    _deepLinkJobLookupCache[jobId] = lookup;
    return lookup;
  }

  Future<_UserLookupCache> _performGetUserLookup(String userId) async {
    _pruneStaleLookups();
    final cached = _deepLinkUserLookupCache[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _deepLinkLookupTtl) {
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
    _deepLinkUserLookupCache[userId] = lookup;
    return lookup;
  }

  Future<_MarketLookupCache> _performGetMarketLookup(String itemId) async {
    _pruneStaleLookups();
    final cached = _deepLinkMarketLookupCache[itemId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _deepLinkLookupTtl) {
      return cached;
    }
    final lookup = _MarketLookupCache(
      model: await ensureMarketRepository().fetchById(
        itemId,
        preferCache: true,
      ),
      cachedAt: DateTime.now(),
    );
    _deepLinkMarketLookupCache[itemId] = lookup;
    return lookup;
  }

  Future<_StoryDocLookupCache> _performGetStoryDocLookup(String storyId) async {
    _pruneStaleLookups();
    final cached = _deepLinkStoryDocLookupCache[storyId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _deepLinkLookupTtl) {
      return cached;
    }
    final storyDoc =
        await StoryRepository.ensure().getStoryRaw(storyId, preferCache: true);
    final lookup = _StoryDocLookupCache(
      data: storyDoc,
      cachedAt: DateTime.now(),
    );
    _deepLinkStoryDocLookupCache[storyId] = lookup;
    return lookup;
  }

  Future<List<StoryModel>> _performFetchStoriesByUserIndexSafe(
    String userId,
  ) async {
    _pruneStaleLookups();
    final cached = _deepLinkStoryListLookupCache[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _deepLinkLookupTtl) {
      return List<StoryModel>.from(cached.stories);
    }

    final stories = await StoryRepository.ensure().getStoriesForUser(
      userId,
      preferCache: true,
      includeDeleted: false,
    );
    _deepLinkStoryListLookupCache[userId] = _StoryListLookupCache(
      stories: List<StoryModel>.from(stories),
      cachedAt: DateTime.now(),
    );
    return stories;
  }

  void _performPruneStaleLookups() {
    final now = DateTime.now();
    bool isStale(DateTime t) => now.difference(t) > _deepLinkStaleRetention;

    _deepLinkPostLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _deepLinkJobLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _deepLinkMarketLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _deepLinkUserLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _deepLinkStoryListLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _deepLinkStoryDocLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _trimOldestIfNeeded();
  }

  void _performTrimOldestIfNeeded() {
    void trimMap<T>(
      Map<String, T> map,
      DateTime Function(T value) cachedAt,
    ) {
      if (map.length <= _deepLinkMaxLookupEntries) return;
      final keysByAge = map.entries.toList()
        ..sort((a, b) => cachedAt(a.value).compareTo(cachedAt(b.value)));
      final removeCount = map.length - _deepLinkMaxLookupEntries;
      for (var i = 0; i < removeCount; i++) {
        map.remove(keysByAge[i].key);
      }
    }

    trimMap<_PostLookupCache>(_deepLinkPostLookupCache, (v) => v.cachedAt);
    trimMap<_JobLookupCache>(_deepLinkJobLookupCache, (v) => v.cachedAt);
    trimMap<_MarketLookupCache>(
      _deepLinkMarketLookupCache,
      (v) => v.cachedAt,
    );
    trimMap<_UserLookupCache>(_deepLinkUserLookupCache, (v) => v.cachedAt);
    trimMap<_StoryListLookupCache>(
      _deepLinkStoryListLookupCache,
      (v) => v.cachedAt,
    );
    trimMap<_StoryDocLookupCache>(
      _deepLinkStoryDocLookupCache,
      (v) => v.cachedAt,
    );
  }
}
