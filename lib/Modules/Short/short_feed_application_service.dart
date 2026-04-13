import 'dart:math' as math;

import 'package:flutter/foundation.dart';

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

  static const Duration _shortLaunchMotorWindow = Duration(days: 7);
  static const int _shortLaunchMotorBandMinutes = 5;
  static const int _shortLaunchMotorSubsliceMs = 200;
  static const List<List<int>> _shortLaunchMotorMinuteSets = <List<int>>[
    <int>[4, 23, 30, 37, 56],
    <int>[5, 18, 25, 44, 51],
    <int>[6, 13, 32, 39, 58],
    <int>[7, 20, 27, 46, 53],
    <int>[8, 15, 34, 41, 48],
    <int>[9, 22, 29, 36, 55],
    <int>[10, 12, 31, 43, 50],
    <int>[11, 17, 24, 38, 57],
    <int>[0, 19, 26, 45, 52],
    <int>[1, 14, 33, 40, 59],
    <int>[2, 21, 28, 47, 54],
    <int>[3, 16, 35, 42, 49],
  ];

  final int Function()? _nowMsProvider;

  ShortInitialLoadPlan buildInitialLoadPlan({
    required List<PostsModel> currentShorts,
    required List<PostsModel> snapshotPosts,
    required bool Function(PostsModel post) isEligiblePost,
  }) {
    final filteredSnapshot = _buildLaunchMotorOrderedItems(
      snapshotPosts.where(isEligiblePost).toList(growable: false),
      targetCount: snapshotPosts.length,
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
  }) {
    final orderedFetchedPosts = _buildLaunchMotorOrderedItems(
      fetchedPosts,
      targetCount: fetchedPosts.length,
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
  }) {
    final existingIds = currentShorts.map((post) => post.docID).toSet();
    final incoming = fetchedPosts
        .where(isEligiblePost)
        .where((post) => !existingIds.contains(post.docID))
        .toList(growable: false);

    return ShortAppendPlan(
      itemsToAppend: _buildLaunchMotorOrderedItems(
        incoming,
        targetCount: incoming.length,
      ),
    );
  }

  List<PostsModel> _buildLaunchMotorOrderedItems(
    List<PostsModel> latestPool, {
    required int targetCount,
  }) {
    if (latestPool.isEmpty || targetCount <= 0) {
      return const <PostsModel>[];
    }

    final normalizedPool = _dedupeByDocId(latestPool)
      ..sort(_compareLatestPosts);
    if (normalizedPool.isEmpty) {
      return const <PostsModel>[];
    }

    final launchAnchorMs = _resolveShortLaunchAnchorMs();
    final launchAnchor = DateTime.fromMillisecondsSinceEpoch(launchAnchorMs);
    final launchMotorIndex = math.min(
      launchAnchor.minute ~/ _shortLaunchMotorBandMinutes,
      _shortLaunchMotorMinuteSets.length - 1,
    );
    final launchSubsliceIndex =
        launchAnchor.minute % _shortLaunchMotorBandMinutes;
    final ownedMinutes =
        _shortLaunchMotorMinuteSets[launchMotorIndex].toList(growable: false);
    final launchWindowStartMs =
        launchAnchorMs - _shortLaunchMotorWindow.inMilliseconds;
    final windowedPool = normalizedPool.where((post) {
      final timestampMs = post.timeStamp.toInt();
      return timestampMs > 0 &&
          timestampMs <= launchAnchorMs &&
          timestampMs >= launchWindowStartMs;
    }).toList(growable: false);
    if (windowedPool.isEmpty) {
      debugPrint(
        '[ShortLaunchMotor] status=empty_window_all_pool '
        'anchor=${launchAnchor.toIso8601String()} motor=$launchMotorIndex '
        'subslice=$launchSubsliceIndex pool=${normalizedPool.length}',
      );
      return const <PostsModel>[];
    }

    final queues = _buildLaunchMotorQueues(
      candidates: windowedPool,
      launchAnchor: launchAnchor,
      launchWindowStartMs: launchWindowStartMs,
      launchMotorIndex: launchMotorIndex,
    );
    if (queues.isEmpty) {
      debugPrint(
        '[ShortLaunchMotor] status=no_queues_strict '
        'anchor=${launchAnchor.toIso8601String()} motor=$launchMotorIndex '
        'subslice=$launchSubsliceIndex pool=${windowedPool.length}',
      );
      final fallback = _sortByLaunchMotorAffinity(
        windowedPool,
        ownedMinutes: ownedMinutes,
        preferredSubsliceIndex: launchSubsliceIndex,
      ).take(targetCount).toList(growable: false);
      debugPrint(
        '[ShortLaunchMotor] status=affinity_fallback '
        'anchor=${launchAnchor.toIso8601String()} motor=$launchMotorIndex '
        'subslice=$launchSubsliceIndex orderedCount=${fallback.length} '
        'sample=${fallback.take(5).map((post) => post.docID).join(",")}',
      );
      return fallback;
    }

    debugPrint(
      '[ShortLaunchMotor] status=queues_ready '
      'anchor=${launchAnchor.toIso8601String()} motor=$launchMotorIndex '
      'subslice=$launchSubsliceIndex pool=${windowedPool.length} '
      'queues=${queues.length}',
    );
    final selected = <PostsModel>[];
    final usedIds = <String>{};
    var appended = true;
    while (appended) {
      appended = false;
      for (final queue in queues) {
        final candidate = queue.takeNext(
          usedIds: usedIds,
          preferredSubsliceIndex: launchSubsliceIndex,
          preferredSubsliceSizeMs: _shortLaunchMotorSubsliceMs,
        );
        if (candidate == null) {
          continue;
        }
        final docId = candidate.docID.trim();
        if (docId.isEmpty || !usedIds.add(docId)) {
          continue;
        }
        selected.add(candidate);
        appended = true;
      }
    }
    // Keep short motor strict once it found owned queues; do not backfill
    // non-owned candidates into the visible order.
    final sortedCombined = _sortLaunchMotorSelectionLatestFirst(
      selected.take(targetCount).toList(growable: false),
    );
    debugPrint(
      '[ShortLaunchMotor] status=applied targetCount=$targetCount '
      'orderedCount=${sortedCombined.length} '
      'sample=${sortedCombined.take(5).map((post) => post.docID).join(",")}',
    );
    return sortedCombined;
  }

  int _resolveShortLaunchAnchorMs() {
    return (_nowMsProvider ?? _defaultNowMsProvider).call();
  }

  static int _defaultNowMsProvider() => DateTime.now().millisecondsSinceEpoch;

  List<_ShortLaunchMinuteQueue> _buildLaunchMotorQueues({
    required List<PostsModel> candidates,
    required DateTime launchAnchor,
    required int launchWindowStartMs,
    required int launchMotorIndex,
  }) {
    final ownedMinutes = _shortLaunchMotorMinuteSets[launchMotorIndex]
        .toList(growable: false)
      ..sort((left, right) => right.compareTo(left));
    final ownedMinuteSet = ownedMinutes.toSet();
    final grouped = <int, List<PostsModel>>{};

    for (final post in candidates) {
      final timestampMs = post.timeStamp.toInt();
      if (timestampMs <= 0 || timestampMs < launchWindowStartMs) {
        continue;
      }
      final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      if (!ownedMinuteSet.contains(timestamp.minute)) {
        continue;
      }
      final queueAnchor = DateTime(
        timestamp.year,
        timestamp.month,
        timestamp.day,
        timestamp.hour,
        timestamp.minute,
      ).millisecondsSinceEpoch;
      grouped.putIfAbsent(queueAnchor, () => <PostsModel>[]).add(post);
    }

    for (final items in grouped.values) {
      items.sort(_compareLatestPosts);
    }

    final queues = <_ShortLaunchMinuteQueue>[];
    var hourCursor = DateTime(
      launchAnchor.year,
      launchAnchor.month,
      launchAnchor.day,
      launchAnchor.hour,
    );

    while (hourCursor.millisecondsSinceEpoch >= launchWindowStartMs) {
      for (final minute in ownedMinutes) {
        if (hourCursor.year == launchAnchor.year &&
            hourCursor.month == launchAnchor.month &&
            hourCursor.day == launchAnchor.day &&
            hourCursor.hour == launchAnchor.hour &&
            minute > launchAnchor.minute) {
          continue;
        }
        final queueAnchor = DateTime(
          hourCursor.year,
          hourCursor.month,
          hourCursor.day,
          hourCursor.hour,
          minute,
        ).millisecondsSinceEpoch;
        final items = grouped[queueAnchor];
        if (items == null || items.isEmpty) {
          continue;
        }
        queues.add(
          _ShortLaunchMinuteQueue(
            anchorMs: queueAnchor,
            items: items,
          ),
        );
      }
      hourCursor = hourCursor.subtract(const Duration(hours: 1));
    }

    return queues;
  }

  List<PostsModel> _dedupeByDocId(List<PostsModel> posts) {
    final seenIds = <String>{};
    final deduped = <PostsModel>[];
    for (final post in posts) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenIds.add(docId)) {
        continue;
      }
      deduped.add(post);
    }
    return deduped;
  }

  int _compareLatestPosts(PostsModel left, PostsModel right) {
    final timeCompare = right.timeStamp.compareTo(left.timeStamp);
    if (timeCompare != 0) {
      return timeCompare;
    }
    return right.docID.trim().compareTo(left.docID.trim());
  }

  List<PostsModel> _sortByLaunchMotorAffinity(
    List<PostsModel> candidates, {
    required List<int> ownedMinutes,
    required int preferredSubsliceIndex,
  }) {
    final sorted = candidates.toList(growable: true)
      ..sort((left, right) {
        final leftMinuteDistance = _launchMotorMinuteDistanceScore(
          minute: DateTime.fromMillisecondsSinceEpoch(left.timeStamp.toInt())
              .minute,
          ownedMinutes: ownedMinutes,
        );
        final rightMinuteDistance = _launchMotorMinuteDistanceScore(
          minute: DateTime.fromMillisecondsSinceEpoch(right.timeStamp.toInt())
              .minute,
          ownedMinutes: ownedMinutes,
        );
        if (leftMinuteDistance != rightMinuteDistance) {
          return leftMinuteDistance.compareTo(rightMinuteDistance);
        }

        final leftSubsliceDistance = _launchMotorSubsliceDistanceScore(
          timestampMs: left.timeStamp.toInt(),
          preferredSubsliceIndex: preferredSubsliceIndex,
        );
        final rightSubsliceDistance = _launchMotorSubsliceDistanceScore(
          timestampMs: right.timeStamp.toInt(),
          preferredSubsliceIndex: preferredSubsliceIndex,
        );
        if (leftSubsliceDistance != rightSubsliceDistance) {
          return leftSubsliceDistance.compareTo(rightSubsliceDistance);
        }

        return _compareLatestPosts(left, right);
      });
    return sorted;
  }

  int _launchMotorMinuteDistanceScore({
    required int minute,
    required List<int> ownedMinutes,
  }) {
    var best = 60;
    for (final ownedMinute in ownedMinutes) {
      final distance = (minute - ownedMinute).abs();
      final wrappedDistance = 60 - distance;
      best = math.min(best, math.min(distance, wrappedDistance));
    }
    return best;
  }

  int _launchMotorSubsliceDistanceScore({
    required int timestampMs,
    required int preferredSubsliceIndex,
  }) {
    final currentSubslice =
        ((timestampMs % 1000) ~/ _shortLaunchMotorSubsliceMs).clamp(0, 4);
    return (currentSubslice - preferredSubsliceIndex).abs();
  }

  List<PostsModel> _sortLaunchMotorSelectionLatestFirst(
    List<PostsModel> items,
  ) {
    if (items.length < 2) {
      return items;
    }
    final sorted = items.toList(growable: false);
    sorted.sort(_compareLatestPosts);
    return sorted;
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

class _ShortLaunchMinuteQueue {
  _ShortLaunchMinuteQueue({
    required this.anchorMs,
    required List<PostsModel> items,
  }) : _pending = items.toList(growable: true);

  final int anchorMs;
  final List<PostsModel> _pending;
  bool _servedInitialPick = false;

  PostsModel? takeNext({
    required Set<String> usedIds,
    required int preferredSubsliceIndex,
    required int preferredSubsliceSizeMs,
  }) {
    if (_pending.isEmpty) {
      return null;
    }

    if (!_servedInitialPick) {
      _servedInitialPick = true;
      final preferredStartMs = preferredSubsliceIndex * preferredSubsliceSizeMs;
      final preferredEndMs = preferredStartMs + preferredSubsliceSizeMs;
      for (var index = 0; index < _pending.length; index++) {
        final candidate = _pending[index];
        final docId = candidate.docID.trim();
        if (docId.isEmpty || usedIds.contains(docId)) {
          continue;
        }
        final millisecondOfSecond = candidate.timeStamp.toInt() % 1000;
        if (millisecondOfSecond >= preferredStartMs &&
            millisecondOfSecond < preferredEndMs) {
          return _pending.removeAt(index);
        }
      }
    }

    for (var index = 0; index < _pending.length; index++) {
      final candidate = _pending[index];
      final docId = candidate.docID.trim();
      if (docId.isEmpty || usedIds.contains(docId)) {
        continue;
      }
      return _pending.removeAt(index);
    }

    return null;
  }
}
