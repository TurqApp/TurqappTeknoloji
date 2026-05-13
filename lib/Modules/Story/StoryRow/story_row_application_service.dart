import 'story_user_model.dart';

class StoryRowBootstrapPlan {
  const StoryRowBootstrapPlan({
    required this.shouldSilentRefresh,
  });

  final bool shouldSilentRefresh;
}

class StoryRowApplicationService {
  StoryRowBootstrapPlan buildBootstrapPlan({
    required bool hasUsers,
    required bool shouldSilentRefresh,
  }) {
    return StoryRowBootstrapPlan(
      shouldSilentRefresh: !hasUsers || shouldSilentRefresh,
    );
  }

  bool shouldRunExpireCleanup({
    required DateTime? lastCleanupAt,
    required DateTime now,
    required Duration interval,
  }) {
    return lastCleanupAt == null || now.difference(lastCleanupAt) >= interval;
  }

  List<StoryUserModel> buildOrderedUsers({
    required List<StoryUserModel> fetchedUsers,
    required String currentUid,
    required StoryUserModel? currentUserStory,
    required Set<String> followingIds,
    required bool Function(StoryUserModel user) isAllSeen,
  }) {
    final tempList = List<StoryUserModel>.from(fetchedUsers);
    tempList.removeWhere((user) => user.userID == currentUid);

    int compareStoryUsers(StoryUserModel a, StoryUserModel b) {
      final aFollowing = followingIds.contains(a.userID);
      final bFollowing = followingIds.contains(b.userID);
      if (aFollowing != bFollowing) return aFollowing ? -1 : 1;
      return b.stories.first.createdAt.compareTo(a.stories.first.createdAt);
    }

    final unseen = tempList.where((user) => !isAllSeen(user)).toList()
      ..sort(compareStoryUsers);
    final seen = tempList.where((user) => isAllSeen(user)).toList()
      ..sort(compareStoryUsers);

    return <StoryUserModel>[
      if (currentUserStory != null) currentUserStory,
      ...unseen,
      ...seen,
    ];
  }
}
