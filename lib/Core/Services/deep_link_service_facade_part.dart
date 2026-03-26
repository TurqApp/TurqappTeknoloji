part of 'deep_link_service.dart';

DeepLinkService ensureDeepLinkService() => _ensureDeepLinkService();

DeepLinkService? maybeFindDeepLinkService() => _maybeFindDeepLinkService();

extension DeepLinkServiceFacadePart on DeepLinkService {
  Future<_PostLookupCache> _getPostLookup(String postId) =>
      _performGetPostLookup(postId);

  Future<_JobLookupCache> _getJobLookup(String jobId) =>
      _performGetJobLookup(jobId);

  Future<_UserLookupCache> _getUserLookup(String userId) =>
      _performGetUserLookup(userId);

  Future<_MarketLookupCache> _getMarketLookup(String itemId) =>
      _performGetMarketLookup(itemId);

  Future<_StoryDocLookupCache> _getStoryDocLookup(String storyId) =>
      _performGetStoryDocLookup(storyId);

  void start() => _DeepLinkServiceRuntimeX(this).start();

  Future<void> handle(Uri uri) => _DeepLinkServiceRuntimeX(this).handle(uri);

  Future<bool> _tryDirectFallback(_ParsedDeepLink parsed) =>
      _performTryDirectFallback(parsed);

  _ParsedDeepLink? _parse(Uri uri) => _performParse(uri);

  Future<void> _openPost(String postId) => _performOpenPost(postId);

  Future<void> _openStory(String storyId) => _performOpenStory(storyId);

  Future<void> _openUserProfile(String userId) =>
      _performOpenUserProfile(userId);

  Future<bool> _canOpenUserContent(
    String userId, {
    UserSummary? summary,
  }) =>
      _performCanOpenUserContent(
        userId,
        summary: summary,
      );

  Future<void> _openMarket(String itemId) => _performOpenMarket(itemId);

  Future<List<StoryModel>> _fetchStoriesByUserIndexSafe(String userId) =>
      _performFetchStoriesByUserIndexSafe(userId);

  void _pruneStaleLookups() => _performPruneStaleLookups();

  void _trimOldestIfNeeded() => _performTrimOldestIfNeeded();

  Future<void> _openEducationLink(String entityId) =>
      _performOpenEducationLink(entityId);

  Future<void> _openJob(String jobId) => _performOpenJob(jobId);
}
