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

  _StoryListLookupCache({
    required List<StoryModel> stories,
    required this.cachedAt,
  }) : stories = _cloneDeepLinkStories(stories);
}

class _StoryDocLookupCache {
  final Map<String, dynamic>? data;
  final DateTime cachedAt;

  _StoryDocLookupCache({
    required Map<String, dynamic>? data,
    required this.cachedAt,
  }) : data = data == null ? null : _cloneDeepLinkStoryDocMap(data);
}
