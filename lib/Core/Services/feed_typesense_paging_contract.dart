class FeedTypesensePagingContract {
  const FeedTypesensePagingContract._();

  static bool hasContinuation({
    Object? lastDoc,
    int? nextTypesensePage,
  }) {
    return lastDoc != null && !(lastDoc is int && lastDoc <= 0) ||
        (nextTypesensePage != null && nextTypesensePage > 0);
  }

  static int? resolveNextTypesensePage({
    required int itemCount,
    required int limit,
    required int page,
    required int found,
  }) {
    if (limit <= 0 || page <= 0 || found <= 0) {
      return null;
    }
    if (itemCount < limit) {
      return null;
    }
    return page * limit < found ? page + 1 : null;
  }

  static bool resolvePageHasMore({
    required bool initial,
    required bool liveConnected,
    required int itemCount,
    required int sourcePageLimit,
    Object? lastDoc,
    int? nextTypesensePage,
  }) {
    final continuation = hasContinuation(
      lastDoc: lastDoc,
      nextTypesensePage: nextTypesensePage,
    );
    if (initial && liveConnected) {
      return itemCount > 0 || continuation;
    }
    return continuation && itemCount >= sourcePageLimit;
  }

  static bool resolveTopUpHasMore({
    required int itemCount,
    Object? lastDoc,
    int? nextTypesensePage,
  }) {
    return itemCount > 0 ||
        hasContinuation(
          lastDoc: lastDoc,
          nextTypesensePage: nextTypesensePage,
        );
  }

  static bool resolvePlannedHasMore({
    required bool hasPlannedRemaining,
    required bool canGrowConnectedPlan,
    Object? lastDoc,
    int? nextTypesensePage,
  }) {
    return hasPlannedRemaining ||
        canGrowConnectedPlan ||
        hasContinuation(
          lastDoc: lastDoc,
          nextTypesensePage: nextTypesensePage,
        );
  }

  static bool shouldStopPriming({
    required int plannedCount,
    required int targetLimit,
    required int itemCount,
    required int batchLimit,
    Object? lastDoc,
    int? nextTypesensePage,
  }) {
    if (plannedCount >= targetLimit) {
      return true;
    }
    if (!hasContinuation(
      lastDoc: lastDoc,
      nextTypesensePage: nextTypesensePage,
    )) {
      return true;
    }
    return itemCount < batchLimit;
  }
}
