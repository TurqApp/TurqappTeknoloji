part of 'story_repository.dart';

extension StoryRepositoryQueryFacadePartX on StoryRepository {
  Future<StoryFetchResult> fetchStoryUsers({
    required int limit,
    required bool cacheFirst,
    required String currentUid,
    required List<String> blockedUserIds,
  }) =>
      _performFetchStoryUsers(
        limit: limit,
        cacheFirst: cacheFirst,
        currentUid: currentUid,
        blockedUserIds: blockedUserIds,
      );

  Future<DeletedStoryCachePayload?> restoreDeletedStoriesCache(String uid) =>
      _performRestoreDeletedStoriesCache(uid);

  Future<void> persistDeletedStoriesCache({
    required String uid,
    required List<StoryModel> stories,
    required Map<String, int> deletedAtById,
    required Map<String, String> deleteReasonById,
  }) =>
      _performPersistDeletedStoriesCache(
        uid: uid,
        stories: stories,
        deletedAtById: deletedAtById,
        deleteReasonById: deleteReasonById,
      );

  Future<void> clearDeletedStoriesCache(String uid) =>
      _performClearDeletedStoriesCache(uid);

  Future<DeletedStoryCachePayload> fetchDeletedStories(String uid) =>
      _performFetchDeletedStories(uid);

  Future<Map<String, dynamic>?> getStoryRaw(
    String storyId, {
    bool preferCache = true,
  }) =>
      _performGetStoryRaw(
        storyId,
        preferCache: preferCache,
      );

  Future<List<StoryModel>> getStoriesForUser(
    String userId, {
    bool preferCache = true,
    bool includeDeleted = false,
  }) =>
      _performGetStoriesForUser(
        userId,
        preferCache: preferCache,
        includeDeleted: includeDeleted,
      );

  Future<List<String>> fetchStoryViewerIds(
    String storyId, {
    int limit = 50,
  }) =>
      _performFetchStoryViewerIds(
        storyId,
        limit: limit,
      );

  Future<int> fetchStoryViewerCount(String storyId) =>
      _performFetchStoryViewerCount(storyId);

  Future<List<StoryCommentModel>> fetchStoryComments(
    String storyId, {
    int limit = 50,
  }) =>
      _performFetchStoryComments(
        storyId,
        limit: limit,
      );

  Future<int> fetchStoryCommentCount(String storyId) =>
      _performFetchStoryCommentCount(storyId);
}
