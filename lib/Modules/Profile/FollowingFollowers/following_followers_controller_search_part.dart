part of 'following_followers_controller.dart';

extension FollowingFollowersControllerSearchPart
    on FollowingFollowersController {
  Future<void> searchTakipci() async {
    final plan = _RelationSearchPlan(
      query: normalizeSearchText(searchTakipciController.text),
      cacheKey: 'followers',
      relation: 'followers',
      assignResult: (ids) => takipciler.value = ids,
    );
    await _runRelationSearch(plan);
  }

  Future<void> searchTakipEdilenler() async {
    final plan = _RelationSearchPlan(
      query: normalizeSearchText(searchTakipEdilenController.text),
      cacheKey: 'followings',
      relation: 'followings',
      assignResult: (ids) => takipEdilenler.value = ids,
    );
    await _runRelationSearch(plan);
  }

  Future<void> _runRelationSearch(_RelationSearchPlan plan) async {
    final q = plan.query;
    if (q.length < 3) return;
    _pruneSearchResultCache();

    final cacheId = '${plan.cacheKey}:$q';
    final cached = _searchResultCache[cacheId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= searchResultCacheTtl) {
      plan.assignResult(_normalizedIds(cached.ids));
      return;
    }

    final relationIDs = await _getRelationIdsCached(plan.relation);
    final results = await _filterRelationIdsByQuery(relationIDs, q);
    _searchResultCache[cacheId] = _SearchResultCacheEntry(
      ids: List<String>.from(results),
      cachedAt: DateTime.now(),
    );
    plan.assignResult(_normalizedIds(results));
  }

  Future<Set<String>> _getRelationIdsCached(String relation) async {
    final now = DateTime.now();
    final cached = _relationIdSetCache[relation];
    if (cached != null &&
        now.difference(cached.cachedAt) <= relationSearchCacheTtl) {
      return cached.ids;
    }

    final ids = relation == 'followers'
        ? await _followRepository.getFollowerIds(
            userId,
            preferCache: true,
            forceRefresh: false,
          )
        : await _visibilityPolicy.loadViewerFollowingIds(
            viewerUserId: userId,
            preferCache: true,
            forceRefresh: false,
          );
    _relationIdSetCache[relation] = _RelationIdSetCacheEntry(
      ids: ids,
      cachedAt: now,
    );
    return ids;
  }

  Future<List<String>> _filterRelationIdsByQuery(
    Set<String> relationIds,
    String q,
  ) async {
    if (relationIds.isEmpty) return const <String>[];
    final normalizedQuery = normalizeSearchText(q);
    if (normalizedQuery.isEmpty) {
      return relationIds.toList(growable: false);
    }
    final users = await _userSummaryResolver.resolveMany(
      relationIds.toList(growable: false),
    );
    final results = <String>[];
    for (final id in relationIds) {
      final data = users[id];
      final nickname = normalizeSearchText(data?.nickname ?? '');
      final displayName = normalizeSearchText(data?.displayName ?? '');
      if (nickname.contains(normalizedQuery) ||
          displayName.contains(normalizedQuery)) {
        results.add(id);
      }
    }
    return results;
  }

  void _pruneSearchResultCache() {
    final now = DateTime.now();
    _searchResultCache.removeWhere(
      (_, entry) => now.difference(entry.cachedAt) > searchResultStaleRetention,
    );
    if (_searchResultCache.length <= maxSearchResultEntries) {
      return;
    }
    final entries = _searchResultCache.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = _searchResultCache.length - maxSearchResultEntries;
    for (var i = 0; i < removeCount; i++) {
      _searchResultCache.remove(entries[i].key);
    }
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
