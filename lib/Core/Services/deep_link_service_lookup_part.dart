part of 'deep_link_service.dart';

Map<String, dynamic> _cloneDeepLinkStoryDocMap(Map<String, dynamic> source) {
  return source.map(
    (key, value) => MapEntry(key, _cloneDeepLinkStoryDocValue(value)),
  );
}

dynamic _cloneDeepLinkStoryDocValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _cloneDeepLinkStoryDocValue(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value.map(_cloneDeepLinkStoryDocValue).toList(growable: false);
  }
  return value;
}

List<StoryModel> _cloneDeepLinkStories(List<StoryModel> stories) {
  return stories
      .map((story) => StoryModel.fromCacheMap(story.toCacheMap()))
      .toList(growable: false);
}

PostsModel? _cloneDeepLinkPostModel(PostsModel? model) {
  if (model == null) return null;
  return PostsModel.fromMap(model.toMap(), model.docID);
}

JobModel? _cloneDeepLinkJobModel(JobModel? model) {
  if (model == null) return null;
  return JobModel.fromMap(model.toMap(), model.docID);
}

MarketItemModel? _cloneDeepLinkMarketModel(MarketItemModel? model) {
  if (model == null) return null;
  return MarketItemModel.fromJson(model.toJson());
}

UserSummary? _cloneDeepLinkUserSummary(UserSummary? data) {
  if (data == null) return null;
  return UserSummary.fromMap(data.userID, data.toMap());
}

_PostLookupCache _cloneDeepLinkPostLookup(_PostLookupCache cached) {
  return _PostLookupCache(
    model: _cloneDeepLinkPostModel(cached.model),
    cachedAt: cached.cachedAt,
  );
}

_JobLookupCache _cloneDeepLinkJobLookup(_JobLookupCache cached) {
  return _JobLookupCache(
    model: _cloneDeepLinkJobModel(cached.model),
    cachedAt: cached.cachedAt,
  );
}

_MarketLookupCache _cloneDeepLinkMarketLookup(_MarketLookupCache cached) {
  return _MarketLookupCache(
    model: _cloneDeepLinkMarketModel(cached.model as MarketItemModel?),
    cachedAt: cached.cachedAt,
  );
}

_UserLookupCache _cloneDeepLinkUserLookup(_UserLookupCache cached) {
  return _UserLookupCache(
    data: _cloneDeepLinkUserSummary(cached.data),
    cachedAt: cached.cachedAt,
  );
}

_StoryDocLookupCache _cloneDeepLinkStoryDocLookup(_StoryDocLookupCache cached) {
  return _StoryDocLookupCache(
    data: cached.data == null ? null : _cloneDeepLinkStoryDocMap(cached.data!),
    cachedAt: cached.cachedAt,
  );
}

extension DeepLinkServiceLookupPart on DeepLinkService {
  Future<_PostLookupCache> _performGetPostLookup(String postId) async {
    _pruneStaleLookups();
    final cached = _deepLinkPostLookupCache[postId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _deepLinkLookupTtl) {
      return _cloneDeepLinkPostLookup(cached);
    }
    final doc =
        (await PostRepository.ensure().fetchPostCardsByIds([postId]))[postId];
    final lookup = _PostLookupCache(
      model: _cloneDeepLinkPostModel(doc),
      cachedAt: DateTime.now(),
    );
    _deepLinkPostLookupCache[postId] = lookup;
    return _cloneDeepLinkPostLookup(lookup);
  }

  Future<_JobLookupCache> _performGetJobLookup(String jobId) async {
    _pruneStaleLookups();
    final cached = _deepLinkJobLookupCache[jobId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _deepLinkLookupTtl) {
      return _cloneDeepLinkJobLookup(cached);
    }
    final lookup = _JobLookupCache(
      model: _cloneDeepLinkJobModel(await ensureJobRepository().fetchById(
        jobId,
        preferCache: true,
      )),
      cachedAt: DateTime.now(),
    );
    _deepLinkJobLookupCache[jobId] = lookup;
    return _cloneDeepLinkJobLookup(lookup);
  }

  Future<_UserLookupCache> _performGetUserLookup(String userId) async {
    _pruneStaleLookups();
    final cached = _deepLinkUserLookupCache[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _deepLinkLookupTtl) {
      return _cloneDeepLinkUserLookup(cached);
    }
    final data = await _userSummaryResolver.resolve(
      userId,
      preferCache: true,
    );
    final lookup = _UserLookupCache(
      data: _cloneDeepLinkUserSummary(data),
      cachedAt: DateTime.now(),
    );
    _deepLinkUserLookupCache[userId] = lookup;
    return _cloneDeepLinkUserLookup(lookup);
  }

  Future<_MarketLookupCache> _performGetMarketLookup(String itemId) async {
    _pruneStaleLookups();
    final cached = _deepLinkMarketLookupCache[itemId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _deepLinkLookupTtl) {
      return _cloneDeepLinkMarketLookup(cached);
    }
    final lookup = _MarketLookupCache(
      model: _cloneDeepLinkMarketModel(await ensureMarketRepository().fetchById(
        itemId,
        preferCache: true,
      )),
      cachedAt: DateTime.now(),
    );
    _deepLinkMarketLookupCache[itemId] = lookup;
    return _cloneDeepLinkMarketLookup(lookup);
  }

  Future<_StoryDocLookupCache> _performGetStoryDocLookup(String storyId) async {
    _pruneStaleLookups();
    final cached = _deepLinkStoryDocLookupCache[storyId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _deepLinkLookupTtl) {
      return _cloneDeepLinkStoryDocLookup(cached);
    }
    final storyDoc =
        await StoryRepository.ensure().getStoryRaw(storyId, preferCache: true);
    final lookup = _StoryDocLookupCache(
      data: storyDoc == null ? null : _cloneDeepLinkStoryDocMap(storyDoc),
      cachedAt: DateTime.now(),
    );
    _deepLinkStoryDocLookupCache[storyId] = lookup;
    return _cloneDeepLinkStoryDocLookup(lookup);
  }

  Future<List<StoryModel>> _performFetchStoriesByUserIndexSafe(
    String userId,
  ) async {
    _pruneStaleLookups();
    final cached = _deepLinkStoryListLookupCache[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _deepLinkLookupTtl) {
      return _cloneDeepLinkStories(cached.stories);
    }

    final stories = await StoryRepository.ensure().getStoriesForUser(
      userId,
      preferCache: true,
      includeDeleted: false,
    );
    _deepLinkStoryListLookupCache[userId] = _StoryListLookupCache(
      stories: _cloneDeepLinkStories(stories),
      cachedAt: DateTime.now(),
    );
    return _cloneDeepLinkStories(stories);
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
