import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Services/launch_motor_selection_service.dart';
import 'package:turqappv2/Core/Services/launch_motor_surface_contract.dart';

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
  ShortFeedApplicationService({
    int Function()? nowMsProvider,
  }) : _nowMsProvider = nowMsProvider;

  static final Duration _shortLaunchMotorWindow =
      shortLaunchMotorContract.window;
  static final int _shortLaunchMotorBandMinutes =
      shortLaunchMotorContract.bandMinutes;
  static final int _shortLaunchMotorSubsliceMs =
      shortLaunchMotorContract.subsliceMs;
  static final List<List<int>> _shortLaunchMotorMinuteSets =
      shortLaunchMotorContract.minuteSets;

  final int Function()? _nowMsProvider;

  int resolveLaunchMotorAnchorMs() => _resolveShortLaunchAnchorMs();

  int resolveLaunchMotorIndex({int? anchorMs}) {
    final resolvedAnchorMs = anchorMs ?? resolveLaunchMotorAnchorMs();
    return LaunchMotorSelectionService.resolveMotorIndex(
      anchorMs: resolvedAnchorMs,
      bandMinutes: _shortLaunchMotorBandMinutes,
      minuteSets: _shortLaunchMotorMinuteSets,
    );
  }

  List<int> resolveLaunchMotorOwnedMinutes({int? anchorMs}) {
    final resolvedAnchorMs = anchorMs ?? resolveLaunchMotorAnchorMs();
    return LaunchMotorSelectionService.resolveOwnedMinutes(
      anchorMs: resolvedAnchorMs,
      bandMinutes: _shortLaunchMotorBandMinutes,
      minuteSets: _shortLaunchMotorMinuteSets,
    );
  }

  List<PostsModel> buildLaunchMotorPool(
    List<PostsModel> latestPool, {
    required int targetCount,
  }) {
    return _buildLaunchMotorOrderedItems(
      latestPool,
      targetCount: targetCount,
    );
  }

  ShortInitialLoadPlan buildInitialLoadPlan({
    required List<PostsModel> currentShorts,
    required List<PostsModel> snapshotPosts,
    required bool Function(PostsModel post) isEligiblePost,
    bool snapshotPostsPreplanned = false,
  }) {
    final eligibleSnapshot =
        snapshotPosts.where(isEligiblePost).toList(growable: false);
    final filteredSnapshot = _resolveVisibleShortOrder(
      eligibleSnapshot,
      targetCount: snapshotPosts.length,
      preplanned: snapshotPostsPreplanned,
    );
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
    bool fetchedPostsPreplanned = false,
  }) {
    final orderedFetchedPosts = _resolveVisibleShortOrder(
      fetchedPosts,
      targetCount: fetchedPosts.length,
      preplanned: fetchedPostsPreplanned,
    );
    final boundedPreviousIndex = previousShorts.isEmpty
        ? 0
        : previousIndex.clamp(0, previousShorts.length - 1);
    final previousDocId = previousShorts.isEmpty
        ? ''
        : previousShorts[boundedPreviousIndex].docID;
    final remappedIndex = previousDocId.isEmpty
        ? 0
        : orderedFetchedPosts.indexWhere((item) => item.docID == previousDocId);

    return ShortRefreshPlan(
      replacementItems: List<PostsModel>.from(orderedFetchedPosts),
      remappedIndex: remappedIndex >= 0
          ? remappedIndex
          : math.min(boundedPreviousIndex, orderedFetchedPosts.length - 1),
    );
  }

  ShortAppendPlan buildAppendPlan({
    required List<PostsModel> currentShorts,
    required List<PostsModel> fetchedPosts,
    required bool Function(PostsModel post) isEligiblePost,
    bool fetchedPostsPreplanned = false,
  }) {
    final existingIds = currentShorts.map((post) => post.docID).toSet();
    final incoming = fetchedPosts
        .where(isEligiblePost)
        .where((post) => !existingIds.contains(post.docID))
        .toList(growable: false);

    return ShortAppendPlan(
      itemsToAppend: _resolveVisibleShortOrder(
        incoming,
        targetCount: incoming.length,
        preplanned: fetchedPostsPreplanned,
      ),
    );
  }

  List<PostsModel> _resolveVisibleShortOrder(
    List<PostsModel> posts, {
    required int targetCount,
    required bool preplanned,
  }) {
    if (posts.isEmpty || targetCount <= 0) {
      return const <PostsModel>[];
    }
    if (preplanned) {
      return _dedupePreservingOrder(posts);
    }
    final motorOrdered = buildLaunchMotorPool(
      posts,
      targetCount: targetCount,
    );
    if (motorOrdered.isNotEmpty) {
      return motorOrdered;
    }
    return _dedupePreservingOrder(posts);
  }

  List<PostsModel> _buildLaunchMotorOrderedItems(
    List<PostsModel> latestPool, {
    required int targetCount,
  }) {
    if (latestPool.isEmpty || targetCount <= 0) {
      return const <PostsModel>[];
    }

    final snapshot = LaunchMotorSelectionService.analyzePool(
      latestPool: latestPool,
      anchorMs: resolveLaunchMotorAnchorMs(),
      window: _shortLaunchMotorWindow,
      bandMinutes: _shortLaunchMotorBandMinutes,
      subsliceMs: _shortLaunchMotorSubsliceMs,
      minuteSets: _shortLaunchMotorMinuteSets,
    );
    if (snapshot.normalizedPool.isEmpty) {
      return const <PostsModel>[];
    }
    if (snapshot.windowedPool.isEmpty) {
      debugPrint(
        '[ShortLaunchMotor] status=empty_window_all_pool '
        'anchor=${snapshot.anchor.toIso8601String()} motor=${snapshot.motorIndex} '
        'subslice=${snapshot.subsliceIndex} pool=${snapshot.normalizedPool.length}',
      );
      return const <PostsModel>[];
    }
    if (!snapshot.hasQueues) {
      debugPrint(
        '[ShortLaunchMotor] status=no_queues_strict '
        'anchor=${snapshot.anchor.toIso8601String()} motor=${snapshot.motorIndex} '
        'subslice=${snapshot.subsliceIndex} pool=${snapshot.windowedPool.length}',
      );
      return const <PostsModel>[];
    }

    debugPrint(
      '[ShortLaunchMotor] status=queues_ready '
      'anchor=${snapshot.anchor.toIso8601String()} motor=${snapshot.motorIndex} '
      'subslice=${snapshot.subsliceIndex} pool=${snapshot.windowedPool.length} '
      'queues=${snapshot.queueCount}',
    );
    // Keep short motor strict once it found owned queues; do not backfill
    // non-owned candidates into the visible order.
    final sortedCombined = _sortNewestFirst(
      snapshot.strictSelection.take(targetCount).toList(growable: false),
    );
    debugPrint(
      '[ShortLaunchMotor] status=applied targetCount=$targetCount '
      'orderedCount=${sortedCombined.length} '
      'sample=${sortedCombined.take(5).map((post) => post.docID).join(",")}',
    );
    return sortedCombined;
  }

  List<PostsModel> _sortNewestFirst(List<PostsModel> items) {
    if (items.length < 2) {
      return items.toList(growable: false);
    }
    final sorted = items.toList(growable: false)
      ..sort((left, right) =>
          LaunchMotorSelectionService.compareLatestPosts(left, right));
    return sorted;
  }

  int _resolveShortLaunchAnchorMs() {
    return (_nowMsProvider ?? _defaultNowMsProvider).call();
  }

  static int _defaultNowMsProvider() => DateTime.now().millisecondsSinceEpoch;

  List<PostsModel> _dedupePreservingOrder(List<PostsModel> posts) {
    if (posts.isEmpty) {
      return const <PostsModel>[];
    }
    final ordered = <PostsModel>[];
    final seenIds = <String>{};
    for (final post in posts) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenIds.add(docId)) {
        continue;
      }
      ordered.add(post);
    }
    return ordered;
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
