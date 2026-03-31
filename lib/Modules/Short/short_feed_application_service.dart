import 'dart:math' as math;

import '../../Models/posts_model.dart';

class ShortInitialLoadPlan {
  const ShortInitialLoadPlan({
    required this.replacementItems,
    required this.shouldScheduleBackgroundRefresh,
    required this.shouldBootstrapNextPage,
    required this.shouldResetPagination,
  });

  final List<PostsModel>? replacementItems;
  final bool shouldScheduleBackgroundRefresh;
  final bool shouldBootstrapNextPage;
  final bool shouldResetPagination;
}

class ShortRefreshPlan {
  const ShortRefreshPlan({
    required this.replacementItems,
    required this.remappedIndex,
  });

  final List<PostsModel> replacementItems;
  final int remappedIndex;
}

class ShortAppendPlan {
  const ShortAppendPlan({
    required this.itemsToAppend,
  });

  final List<PostsModel> itemsToAppend;
}

class ShortFeedApplicationService {
  ShortInitialLoadPlan buildInitialLoadPlan({
    required List<PostsModel> currentShorts,
    required List<PostsModel> snapshotPosts,
    required bool Function(PostsModel post) isEligiblePost,
  }) {
    final filteredSnapshot =
        snapshotPosts.where(isEligiblePost).toList(growable: false);
    if (currentShorts.isEmpty) {
      if (filteredSnapshot.isNotEmpty) {
        return ShortInitialLoadPlan(
          replacementItems: filteredSnapshot,
          shouldScheduleBackgroundRefresh: true,
          shouldBootstrapNextPage: false,
          shouldResetPagination: false,
        );
      }
      return const ShortInitialLoadPlan(
        replacementItems: null,
        shouldScheduleBackgroundRefresh: false,
        shouldBootstrapNextPage: true,
        shouldResetPagination: true,
      );
    }

    final sanitizedCurrent =
        currentShorts.where(isEligiblePost).toList(growable: false);
    if (_hasSameDocOrder(currentShorts, sanitizedCurrent)) {
      return const ShortInitialLoadPlan(
        replacementItems: null,
        shouldScheduleBackgroundRefresh: false,
        shouldBootstrapNextPage: false,
        shouldResetPagination: false,
      );
    }

    return ShortInitialLoadPlan(
      replacementItems: sanitizedCurrent,
      shouldScheduleBackgroundRefresh: false,
      shouldBootstrapNextPage: false,
      shouldResetPagination: false,
    );
  }

  ShortRefreshPlan buildRefreshPlan({
    required List<PostsModel> previousShorts,
    required List<PostsModel> fetchedPosts,
    required int previousIndex,
  }) {
    final boundedPreviousIndex = previousShorts.isEmpty
        ? 0
        : previousIndex.clamp(0, previousShorts.length - 1);
    final previousDocId = previousShorts.isEmpty
        ? ''
        : previousShorts[boundedPreviousIndex].docID;
    final remappedIndex = previousDocId.isEmpty
        ? 0
        : fetchedPosts.indexWhere((item) => item.docID == previousDocId);

    return ShortRefreshPlan(
      replacementItems: List<PostsModel>.from(fetchedPosts),
      remappedIndex: remappedIndex >= 0
          ? remappedIndex
          : math.min(boundedPreviousIndex, fetchedPosts.length - 1),
    );
  }

  ShortAppendPlan buildAppendPlan({
    required List<PostsModel> currentShorts,
    required List<PostsModel> fetchedPosts,
    required bool Function(PostsModel post) isEligiblePost,
  }) {
    final existingIds = currentShorts.map((post) => post.docID).toSet();
    final incoming = fetchedPosts
        .where(isEligiblePost)
        .where((post) => !existingIds.contains(post.docID))
        .toList(growable: false);

    return ShortAppendPlan(
      itemsToAppend: incoming,
    );
  }

  bool _hasSameDocOrder(
    List<PostsModel> left,
    List<PostsModel> right,
  ) {
    if (left.length != right.length) return false;
    for (int i = 0; i < left.length; i++) {
      if (left[i].docID != right[i].docID) return false;
    }
    return true;
  }
}
