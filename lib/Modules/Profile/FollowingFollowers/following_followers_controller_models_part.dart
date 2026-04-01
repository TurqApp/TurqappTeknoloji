part of 'following_followers_controller.dart';

class _NicknameCacheEntry {
  final String nickname;
  final DateTime cachedAt;

  const _NicknameCacheEntry({
    required this.nickname,
    required this.cachedAt,
  });
}

class _RelationIdSetCacheEntry {
  final Set<String> ids;
  final DateTime cachedAt;

  const _RelationIdSetCacheEntry({
    required this.ids,
    required this.cachedAt,
  });
}

class _SearchResultCacheEntry {
  final List<String> ids;
  final DateTime cachedAt;

  const _SearchResultCacheEntry({
    required this.ids,
    required this.cachedAt,
  });
}

class _CounterCacheEntry {
  final int followers;
  final int followings;
  final DateTime cachedAt;

  const _CounterCacheEntry({
    required this.followers,
    required this.followings,
    required this.cachedAt,
  });
}

class _RelationListCacheEntry {
  final List<String> ids;
  final DateTime cachedAt;

  const _RelationListCacheEntry({
    required this.ids,
    required this.cachedAt,
  });
}

class _RelationSearchPlan {
  const _RelationSearchPlan({
    required this.query,
    required this.cacheKey,
    required this.relation,
    required this.assignResult,
  });

  final String query;
  final String cacheKey;
  final String relation;
  final void Function(List<String> ids) assignResult;
}
