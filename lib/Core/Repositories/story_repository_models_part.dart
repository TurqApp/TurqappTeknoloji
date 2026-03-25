part of 'story_repository.dart';

class DeletedStoryCachePayload {
  const DeletedStoryCachePayload({
    required this.stories,
    required this.deletedAtById,
    required this.deleteReasonById,
  });

  final List<StoryModel> stories;
  final Map<String, int> deletedAtById;
  final Map<String, String> deleteReasonById;
}

class StoryFetchResult {
  const StoryFetchResult({
    required this.users,
    required this.cacheHit,
  });

  final List<StoryUserModel> users;
  final bool cacheHit;
}

class StoryEngagementSnapshot {
  const StoryEngagementSnapshot({
    required this.likeCount,
    required this.isLiked,
    required this.reactionCounts,
    required this.myReaction,
  });

  final int likeCount;
  final bool isLiked;
  final Map<String, int> reactionCounts;
  final String myReaction;
}
