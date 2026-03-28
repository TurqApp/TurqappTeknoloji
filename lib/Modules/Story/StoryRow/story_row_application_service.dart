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
    required bool Function(StoryUserModel user) isAllSeen,
  }) {
    final tempList = List<StoryUserModel>.from(fetchedUsers);
    tempList.removeWhere((user) => user.userID == currentUid);

    final unseen = tempList.where((user) => !isAllSeen(user)).toList()
      ..sort(
        (a, b) =>
            b.stories.first.createdAt.compareTo(a.stories.first.createdAt),
      );
    final seen = tempList.where((user) => isAllSeen(user)).toList()
      ..sort(
        (a, b) =>
            b.stories.first.createdAt.compareTo(a.stories.first.createdAt),
      );

    return <StoryUserModel>[
      if (currentUserStory != null) currentUserStory,
      ...unseen,
      ...seen,
    ];
  }
}
