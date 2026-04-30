part of 'deep_link_service.dart';

class _PostLookupCache {
  final PostsModel? model;
  final DateTime cachedAt;

  _PostLookupCache({
    required PostsModel? model,
    required this.cachedAt,
  }) : model = _cloneDeepLinkPostModel(model);
}

class _JobLookupCache {
  final JobModel? model;
  final DateTime cachedAt;

  _JobLookupCache({
    required JobModel? model,
    required this.cachedAt,
  }) : model = _cloneDeepLinkJobModel(model);
}

class _MarketLookupCache {
  final dynamic model;
  final DateTime cachedAt;

  _MarketLookupCache({
    required dynamic model,
    required this.cachedAt,
  }) : model = _cloneDeepLinkMarketModel(model as MarketItemModel?);
}

class _UserLookupCache {
  final UserSummary? data;
  final DateTime cachedAt;

  _UserLookupCache({
    required UserSummary? data,
    required this.cachedAt,
  }) : data = _cloneDeepLinkUserSummary(data);
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
