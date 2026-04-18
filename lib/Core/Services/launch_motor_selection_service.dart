import 'dart:math' as math;

import 'package:turqappv2/Core/Services/launch_motor_surface_contract.dart';
import 'package:turqappv2/Models/posts_model.dart';

class LaunchMotorSelectionSnapshot {
  const LaunchMotorSelectionSnapshot({
    required this.anchorMs,
    required this.anchor,
    required this.motorIndex,
    required this.subsliceIndex,
    required this.ownedMinutes,
    required this.normalizedPool,
    required this.windowedPool,
    required this.queueCount,
    required this.strictSelection,
  });

  final int anchorMs;
  final DateTime anchor;
  final int motorIndex;
  final int subsliceIndex;
  final List<int> ownedMinutes;
  final List<PostsModel> normalizedPool;
  final List<PostsModel> windowedPool;
  final int queueCount;
  final List<PostsModel> strictSelection;

  bool get hasQueues => queueCount > 0;
}

class LaunchMotorPoolFillResult {
  const LaunchMotorPoolFillResult({
    required this.snapshot,
    required this.selectedPool,
  });

  final LaunchMotorSelectionSnapshot snapshot;
  final List<PostsModel> selectedPool;

  int get strictCount => snapshot.strictSelection.length;
  bool needsTopUp(int targetCount) => strictCount < targetCount;
}

class LaunchMotorSelectionService {
  const LaunchMotorSelectionService._();

  static int resolveMotorIndex({
    required int anchorMs,
    required int bandMinutes,
    required List<List<int>> minuteSets,
  }) {
    if (minuteSets.isEmpty || bandMinutes <= 0) {
      return 0;
    }
    final anchor = DateTime.fromMillisecondsSinceEpoch(anchorMs);
    return math.min(
      anchor.minute ~/ bandMinutes,
      minuteSets.length - 1,
    );
  }

  static List<int> resolveOwnedMinutes({
    required int anchorMs,
    required int bandMinutes,
    required List<List<int>> minuteSets,
  }) {
    if (minuteSets.isEmpty) {
      return const <int>[];
    }
    final motorIndex = resolveMotorIndex(
      anchorMs: anchorMs,
      bandMinutes: bandMinutes,
      minuteSets: minuteSets,
    );
    return minuteSets[motorIndex].toList(growable: false);
  }

  static LaunchMotorSelectionSnapshot analyzePool({
    required List<PostsModel> latestPool,
    required int anchorMs,
    required Duration window,
    required int bandMinutes,
    required int subsliceMs,
    required List<List<int>> minuteSets,
  }) {
    final normalizedPool = dedupeLatestFirst(latestPool);
    final anchor = DateTime.fromMillisecondsSinceEpoch(anchorMs);
    if (normalizedPool.isEmpty) {
      return LaunchMotorSelectionSnapshot(
        anchorMs: anchorMs,
        anchor: anchor,
        motorIndex: 0,
        subsliceIndex: 0,
        ownedMinutes: const <int>[],
        normalizedPool: const <PostsModel>[],
        windowedPool: const <PostsModel>[],
        queueCount: 0,
        strictSelection: const <PostsModel>[],
      );
    }

    final motorIndex = resolveMotorIndex(
      anchorMs: anchorMs,
      bandMinutes: bandMinutes,
      minuteSets: minuteSets,
    );
    final subsliceIndex = bandMinutes <= 0 ? 0 : anchor.minute % bandMinutes;
    final ownedMinutes = resolveOwnedMinutes(
      anchorMs: anchorMs,
      bandMinutes: bandMinutes,
      minuteSets: minuteSets,
    );
    final launchWindowStartMs = anchorMs - window.inMilliseconds;
    final windowedPool = normalizedPool.where((post) {
      final timestampMs = post.timeStamp.toInt();
      return timestampMs > 0 &&
          timestampMs <= anchorMs &&
          timestampMs >= launchWindowStartMs;
    }).toList(growable: false);
    final queues = _buildQueues(
      candidates: windowedPool,
      anchor: anchor,
      launchWindowStartMs: launchWindowStartMs,
      ownedMinutes: ownedMinutes,
    );
    final strictSelection = _selectStrictFromQueues(
      queues: queues,
      preferredSubsliceIndex: subsliceIndex,
      preferredSubsliceSizeMs: subsliceMs,
    );

    return LaunchMotorSelectionSnapshot(
      anchorMs: anchorMs,
      anchor: anchor,
      motorIndex: motorIndex,
      subsliceIndex: subsliceIndex,
      ownedMinutes: ownedMinutes,
      normalizedPool: normalizedPool,
      windowedPool: windowedPool,
      queueCount: queues.length,
      strictSelection: strictSelection,
    );
  }

  static LaunchMotorPoolFillResult buildPoolFillResult({
    required List<PostsModel> latestPool,
    required int anchorMs,
    required LaunchMotorSurfaceContract contract,
    required int targetCount,
    bool fallbackToAffinityWhenSparse = true,
    bool fallbackToLatestWhenEmpty = true,
    bool fallbackToLatestWhenAffinitySparse = false,
  }) {
    final snapshot = analyzePool(
      latestPool: latestPool,
      anchorMs: anchorMs,
      window: contract.window,
      bandMinutes: contract.bandMinutes,
      subsliceMs: contract.subsliceMs,
      minuteSets: contract.minuteSets,
    );
    if (targetCount <= 0 || snapshot.normalizedPool.isEmpty) {
      return LaunchMotorPoolFillResult(
        snapshot: snapshot,
        selectedPool: const <PostsModel>[],
      );
    }
    if (snapshot.strictSelection.isNotEmpty) {
      final selectedPool = <PostsModel>[
        ...sortLatestFirst(
          snapshot.strictSelection.take(targetCount).toList(growable: false),
        ),
      ];
      final usedIds = <String>{
        for (final post in selectedPool)
          if (post.docID.trim().isNotEmpty) post.docID.trim(),
      };
      if (selectedPool.length < targetCount &&
          fallbackToAffinityWhenSparse &&
          snapshot.windowedPool.isNotEmpty) {
        final affinityPool = sortByAffinity(
          snapshot.windowedPool,
          ownedMinutes: snapshot.ownedMinutes,
          preferredSubsliceIndex: snapshot.subsliceIndex,
          subsliceMs: contract.subsliceMs,
        );
        for (final post in affinityPool) {
          final docId = post.docID.trim();
          if (docId.isEmpty || !usedIds.add(docId)) {
            continue;
          }
          selectedPool.add(post);
          if (selectedPool.length >= targetCount) {
            break;
          }
        }
      }
      if (selectedPool.length < targetCount && fallbackToLatestWhenEmpty) {
        for (final post in snapshot.normalizedPool) {
          final docId = post.docID.trim();
          if (docId.isEmpty || !usedIds.add(docId)) {
            continue;
          }
          selectedPool.add(post);
          if (selectedPool.length >= targetCount) {
            break;
          }
        }
      }
      return LaunchMotorPoolFillResult(
        snapshot: snapshot,
        selectedPool: selectedPool,
      );
    }
    if (fallbackToAffinityWhenSparse && snapshot.windowedPool.isNotEmpty) {
      final selectedPool = sortByAffinity(
        snapshot.windowedPool,
        ownedMinutes: snapshot.ownedMinutes,
        preferredSubsliceIndex: snapshot.subsliceIndex,
        subsliceMs: contract.subsliceMs,
      ).take(targetCount).toList(growable: true);
      if (selectedPool.length < targetCount &&
          fallbackToLatestWhenEmpty &&
          fallbackToLatestWhenAffinitySparse) {
        final usedIds = <String>{
          for (final post in selectedPool)
            if (post.docID.trim().isNotEmpty) post.docID.trim(),
        };
        for (final post in snapshot.normalizedPool) {
          final docId = post.docID.trim();
          if (docId.isEmpty || !usedIds.add(docId)) {
            continue;
          }
          selectedPool.add(post);
          if (selectedPool.length >= targetCount) {
            break;
          }
        }
      }
      return LaunchMotorPoolFillResult(
        snapshot: snapshot,
        selectedPool: selectedPool.toList(growable: false),
      );
    }
    if (fallbackToLatestWhenEmpty) {
      return LaunchMotorPoolFillResult(
        snapshot: snapshot,
        selectedPool: sortLatestFirst(
          snapshot.normalizedPool.take(targetCount).toList(growable: false),
        ),
      );
    }
    return LaunchMotorPoolFillResult(
      snapshot: snapshot,
      selectedPool: const <PostsModel>[],
    );
  }

  static List<PostsModel> dedupeLatestFirst(List<PostsModel> posts) {
    if (posts.isEmpty) {
      return const <PostsModel>[];
    }
    final seenIds = <String>{};
    final normalized = <PostsModel>[];
    for (final post in posts) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenIds.add(docId)) {
        continue;
      }
      normalized.add(post);
    }
    normalized.sort(compareLatestPosts);
    return normalized;
  }

  static List<PostsModel> sortLatestFirst(List<PostsModel> items) {
    if (items.length < 2) {
      return items.toList(growable: false);
    }
    final sorted = items.toList(growable: false);
    sorted.sort(compareLatestPosts);
    return sorted;
  }

  static List<PostsModel> sortByAffinity(
    List<PostsModel> candidates, {
    required List<int> ownedMinutes,
    required int preferredSubsliceIndex,
    required int subsliceMs,
  }) {
    final sorted = candidates.toList(growable: true)
      ..sort((left, right) {
        final leftMinuteDistance = _minuteDistanceScore(
          minute: DateTime.fromMillisecondsSinceEpoch(left.timeStamp.toInt())
              .minute,
          ownedMinutes: ownedMinutes,
        );
        final rightMinuteDistance = _minuteDistanceScore(
          minute: DateTime.fromMillisecondsSinceEpoch(right.timeStamp.toInt())
              .minute,
          ownedMinutes: ownedMinutes,
        );
        if (leftMinuteDistance != rightMinuteDistance) {
          return leftMinuteDistance.compareTo(rightMinuteDistance);
        }

        final leftSubsliceDistance = _subsliceDistanceScore(
          timestampMs: left.timeStamp.toInt(),
          preferredSubsliceIndex: preferredSubsliceIndex,
          subsliceMs: subsliceMs,
        );
        final rightSubsliceDistance = _subsliceDistanceScore(
          timestampMs: right.timeStamp.toInt(),
          preferredSubsliceIndex: preferredSubsliceIndex,
          subsliceMs: subsliceMs,
        );
        if (leftSubsliceDistance != rightSubsliceDistance) {
          return leftSubsliceDistance.compareTo(rightSubsliceDistance);
        }

        return compareLatestPosts(left, right);
      });
    return sorted;
  }

  static int compareLatestPosts(PostsModel left, PostsModel right) {
    final timeCompare = right.timeStamp.compareTo(left.timeStamp);
    if (timeCompare != 0) {
      return timeCompare;
    }
    return right.docID.trim().compareTo(left.docID.trim());
  }

  static List<PostsModel> _selectStrictFromQueues({
    required List<_LaunchMinuteQueue> queues,
    required int preferredSubsliceIndex,
    required int preferredSubsliceSizeMs,
  }) {
    if (queues.isEmpty) {
      return const <PostsModel>[];
    }
    final selected = <PostsModel>[];
    final usedIds = <String>{};
    var appended = true;
    while (appended) {
      appended = false;
      for (final queue in queues) {
        final candidate = queue.takeNext(
          usedIds: usedIds,
          preferredSubsliceIndex: preferredSubsliceIndex,
          preferredSubsliceSizeMs: preferredSubsliceSizeMs,
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
    return selected;
  }

  static List<_LaunchMinuteQueue> _buildQueues({
    required List<PostsModel> candidates,
    required DateTime anchor,
    required int launchWindowStartMs,
    required List<int> ownedMinutes,
  }) {
    if (candidates.isEmpty || ownedMinutes.isEmpty) {
      return const <_LaunchMinuteQueue>[];
    }
    final sortedOwnedMinutes = ownedMinutes.toList(growable: false)
      ..sort((left, right) => right.compareTo(left));
    final ownedMinuteSet = sortedOwnedMinutes.toSet();
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
      items.sort(compareLatestPosts);
    }

    final queues = <_LaunchMinuteQueue>[];
    var hourCursor = DateTime(
      anchor.year,
      anchor.month,
      anchor.day,
      anchor.hour,
    );

    while (hourCursor.millisecondsSinceEpoch >= launchWindowStartMs) {
      for (final minute in sortedOwnedMinutes) {
        if (hourCursor.year == anchor.year &&
            hourCursor.month == anchor.month &&
            hourCursor.day == anchor.day &&
            hourCursor.hour == anchor.hour &&
            minute > anchor.minute) {
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
          _LaunchMinuteQueue(
            anchorMs: queueAnchor,
            items: items,
          ),
        );
      }
      hourCursor = hourCursor.subtract(const Duration(hours: 1));
    }

    return queues;
  }

  static int _minuteDistanceScore({
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

  static int _subsliceDistanceScore({
    required int timestampMs,
    required int preferredSubsliceIndex,
    required int subsliceMs,
  }) {
    final safeSubsliceMs = subsliceMs <= 0 ? 200 : subsliceMs;
    final currentSubslice =
        ((timestampMs % 1000) ~/ safeSubsliceMs).clamp(0, 4);
    return (currentSubslice - preferredSubsliceIndex).abs();
  }
}

class _LaunchMinuteQueue {
  _LaunchMinuteQueue({
    required this.anchorMs,
    required List<PostsModel> items,
  }) : _items = items;

  final int anchorMs;
  final List<PostsModel> _items;
  int _nextIndex = 0;

  PostsModel? takeNext({
    required Set<String> usedIds,
    required int preferredSubsliceIndex,
    required int preferredSubsliceSizeMs,
  }) {
    while (_nextIndex < _items.length) {
      final remaining = _items.sublist(_nextIndex);
      remaining.sort((left, right) {
        final leftDistance = LaunchMotorSelectionService._subsliceDistanceScore(
          timestampMs: left.timeStamp.toInt(),
          preferredSubsliceIndex: preferredSubsliceIndex,
          subsliceMs: preferredSubsliceSizeMs,
        );
        final rightDistance =
            LaunchMotorSelectionService._subsliceDistanceScore(
          timestampMs: right.timeStamp.toInt(),
          preferredSubsliceIndex: preferredSubsliceIndex,
          subsliceMs: preferredSubsliceSizeMs,
        );
        if (leftDistance != rightDistance) {
          return leftDistance.compareTo(rightDistance);
        }
        return LaunchMotorSelectionService.compareLatestPosts(left, right);
      });
      _items
        ..removeRange(_nextIndex, _items.length)
        ..addAll(remaining);
      final candidate = _items[_nextIndex++];
      final docId = candidate.docID.trim();
      if (docId.isEmpty || usedIds.contains(docId)) {
        continue;
      }
      return candidate;
    }
    return null;
  }
}
