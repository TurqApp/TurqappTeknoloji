part of 'deep_link_service.dart';

class _ParsedDeepLink {
  final String type;
  final String id;

  _ParsedDeepLink({required this.type, required this.id});
}

class _PostLookupCache {
  final PostsModel? model;
  final DateTime cachedAt;

  const _PostLookupCache({
    required this.model,
    required this.cachedAt,
  });
}

class _JobLookupCache {
  final JobModel? model;
  final DateTime cachedAt;

  const _JobLookupCache({
    required this.model,
    required this.cachedAt,
  });
}

class _MarketLookupCache {
  final dynamic model;
  final DateTime cachedAt;

  const _MarketLookupCache({
    required this.model,
    required this.cachedAt,
  });
}

class _UserLookupCache {
  final UserSummary? data;
  final DateTime cachedAt;

  const _UserLookupCache({
    required this.data,
    required this.cachedAt,
  });
}

class _StoryListLookupCache {
  final List<StoryModel> stories;
  final DateTime cachedAt;

  const _StoryListLookupCache({
    required this.stories,
    required this.cachedAt,
  });
}

class _StoryDocLookupCache {
  final Map<String, dynamic>? data;
  final DateTime cachedAt;

  const _StoryDocLookupCache({
    required this.data,
    required this.cachedAt,
  });
}
