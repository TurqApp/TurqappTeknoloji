part of 'story_repository.dart';

extension StoryRepositoryEngagementFacadePartX on StoryRepository {
  Future<StoryCommentModel?> fetchLatestStoryComment(String storyId) =>
      _performFetchLatestStoryComment(storyId);

  Future<void> addStoryComment(
    String storyId, {
    required String userId,
    required String text,
    required String gif,
  }) =>
      _performAddStoryComment(
        storyId,
        userId: userId,
        text: text,
        gif: gif,
      );

  Future<void> deleteStoryComment(
    String storyId, {
    required String commentId,
  }) =>
      _performDeleteStoryComment(
        storyId,
        commentId: commentId,
      );

  Future<void> addScreenshotEvent(
    String storyId, {
    required String userId,
  }) =>
      _performAddScreenshotEvent(
        storyId,
        userId: userId,
      );

  Future<void> markUserStoriesFullyViewed({
    required String currentUid,
    required String targetUserId,
    required int latestStoryTime,
  }) =>
      _performMarkUserStoriesFullyViewed(
        currentUid: currentUid,
        targetUserId: targetUserId,
        latestStoryTime: latestStoryTime,
      );

  Future<List<String>> fetchStoryLikeIds(String storyId) =>
      _performFetchStoryLikeIds(storyId);

  Future<int> fetchStoryLikeCount(String storyId) =>
      _performFetchStoryLikeCount(storyId);

  Future<StoryEngagementSnapshot> fetchStoryEngagement(
    String storyId, {
    required String currentUid,
  }) =>
      _performFetchStoryEngagement(
        storyId,
        currentUid: currentUid,
      );

  Future<bool> toggleStoryLike(
    String storyId, {
    required String currentUid,
  }) =>
      _performToggleStoryLike(
        storyId,
        currentUid: currentUid,
      );

  Future<String> toggleStoryReaction(
    String storyId, {
    required String currentUid,
    required String emoji,
    required String currentReaction,
  }) =>
      _performToggleStoryReaction(
        storyId,
        currentUid: currentUid,
        emoji: emoji,
        currentReaction: currentReaction,
      );

  Future<void> setStorySeen(
    String storyId, {
    required String currentUid,
  }) =>
      _performSetStorySeen(
        storyId,
        currentUid: currentUid,
      );
}
