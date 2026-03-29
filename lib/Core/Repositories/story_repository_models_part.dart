part of 'story_repository.dart';

List<StoryModel> _cloneDeletedStoryCacheStories(List<StoryModel> stories) {
  return stories
      .map((story) => StoryModel.fromCacheMap(story.toCacheMap()))
      .toList(growable: false);
}

List<StoryUserModel> _cloneStoryFetchUsers(List<StoryUserModel> users) {
  return users
      .map((user) => StoryUserModel.fromCacheMap(user.toCacheMap()))
      .toList(growable: false);
}

class DeletedStoryCachePayload {
  DeletedStoryCachePayload({
    required List<StoryModel> stories,
    required Map<String, int> deletedAtById,
    required Map<String, String> deleteReasonById,
  })  : stories = _cloneDeletedStoryCacheStories(stories),
        deletedAtById = Map<String, int>.from(deletedAtById),
        deleteReasonById = Map<String, String>.from(deleteReasonById);

  final List<StoryModel> stories;
  final Map<String, int> deletedAtById;
  final Map<String, String> deleteReasonById;
}

class StoryFetchResult {
  StoryFetchResult({
    required List<StoryUserModel> users,
    required this.cacheHit,
  }) : users = _cloneStoryFetchUsers(users);

  final List<StoryUserModel> users;
  final bool cacheHit;
}

class StoryEngagementSnapshot {
  StoryEngagementSnapshot({
    required this.likeCount,
    required this.isLiked,
    required Map<String, int> reactionCounts,
    required this.myReaction,
  }) : reactionCounts = Map<String, int>.from(reactionCounts);

  final int likeCount;
  final bool isLiked;
  final Map<String, int> reactionCounts;
  final String myReaction;
}
