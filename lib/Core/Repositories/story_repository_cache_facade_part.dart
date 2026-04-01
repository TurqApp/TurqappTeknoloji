part of 'story_repository.dart';

extension StoryRepositoryCacheFacadeX on StoryRepository {
  Future<void> saveStoryRowCache(
    List<StoryUserModel> list, {
    required String ownerUid,
  }) =>
      _performSaveStoryRowCache(list, ownerUid: ownerUid);

  Future<List<StoryUserModel>> restoreStoryRowCache({
    required String ownerUid,
    bool allowExpired = false,
  }) =>
      _performRestoreStoryRowCache(
        ownerUid: ownerUid,
        allowExpired: allowExpired,
      );

  Future<void> clearStoryRowCacheForCurrentUser(String ownerUid) =>
      _performClearStoryRowCacheForCurrentUser(ownerUid);

  Future<void> invalidateStoryCachesForUser(
    String uid, {
    bool clearDeletedStories = true,
  }) =>
      _performInvalidateStoryCachesForUser(
        uid,
        clearDeletedStories: clearDeletedStories,
      );

  Future<Map<String, StoryModel>> fetchStoriesByIds(List<String> storyIds) =>
      _performFetchStoriesByIds(storyIds);

  Future<StoryModel?> fetchStoryById(
    String storyId, {
    bool preferCache = true,
  }) =>
      _performFetchStoryById(
        storyId,
        preferCache: preferCache,
      );

  Future<List<StoryModel>> fetchActiveStoriesByMusicId(
    String musicId, {
    int limit = 60,
  }) =>
      _performFetchActiveStoriesByMusicId(
        musicId,
        limit: limit,
      );

  Future<void> markExpiredStoriesDeleted(String uid) =>
      _performMarkExpiredStoriesDeleted(uid);

  Future<String> softDeleteStory(
    String storyId, {
    String reason = 'manual',
  }) =>
      _performSoftDeleteStory(
        storyId,
        reason: reason,
      );

  Future<void> restoreDeletedStory(String storyId) =>
      _performRestoreDeletedStory(storyId);

  Future<void> permanentlyDeleteStory(String storyId) =>
      _performPermanentlyDeleteStory(storyId);

  Future<String> repostDeletedStory(StoryModel story) =>
      _performRepostDeletedStory(story);
}
