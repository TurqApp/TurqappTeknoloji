// ignore_for_file: unused_element, unused_local_variable

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Services/feed_diversity_memory_service.dart';
import 'package:turqappv2/Core/Services/feed_render_block_plan.dart';
import 'package:turqappv2/Core/Services/launch_motor_selection_service.dart';
import 'package:turqappv2/Core/Services/launch_motor_surface_contract.dart';
import 'package:turqappv2/Core/Services/startup_surface_order_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

class AgendaFeedPageApplyPlan {
  const AgendaFeedPageApplyPlan({
    required this.itemsToAdd,
    required this.freshScheduledIds,
    required this.hasMore,
    required this.lastDoc,
    required this.usesPrimaryFeed,
    required this.pageItemsPreplanned,
  });

  final List<PostsModel> itemsToAdd;
  final List<String> freshScheduledIds;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool usesPrimaryFeed;
  final bool pageItemsPreplanned;
}

class AgendaFeedRefreshPlan {
  const AgendaFeedRefreshPlan({
    required this.replacementItems,
    required this.freshScheduledIds,
  });

  final List<PostsModel> replacementItems;
  final List<String> freshScheduledIds;
}

class _AgendaFeedPenaltySnapshot {
  const _AgendaFeedPenaltySnapshot({
    required this.startupHeadDocIds,
    required this.startupHeadFloodRootIds,
    required this.weeklyWatchedDocIds,
    required this.weeklyWatchedFloodRootIds,
  });

  const _AgendaFeedPenaltySnapshot.empty()
      : startupHeadDocIds = const <String>{},
        startupHeadFloodRootIds = const <String>{},
        weeklyWatchedDocIds = const <String>{},
        weeklyWatchedFloodRootIds = const <String>{};

  final Set<String> startupHeadDocIds;
  final Set<String> startupHeadFloodRootIds;
  final Set<String> weeklyWatchedDocIds;
  final Set<String> weeklyWatchedFloodRootIds;
}

class AgendaFeedApplicationService {
  AgendaFeedApplicationService({
    int Function()? nowMsProvider,
  }) : _nowMsProvider = nowMsProvider;

  static const int _feedPlannerShuffleWindow = 24;
  static const Duration _livePlannerWindow = Duration(days: 3);
  static final Duration _feedLaunchMotorWindow = feedLaunchMotorContract.window;
  static final int _feedLaunchMotorBandMinutes =
      feedLaunchMotorContract.bandMinutes;
  static final int _feedLaunchMotorSubsliceMs =
      feedLaunchMotorContract.subsliceMs;
  static final List<List<int>> _feedLaunchMotorMinuteSets =
      feedLaunchMotorContract.minuteSets;

  final int Function()? _nowMsProvider;

  int resolveLaunchMotorAnchorMs() =>
      (_nowMsProvider ?? _defaultNowMsProvider).call();

  int resolveLaunchMotorIndex({int? anchorMs}) {
    final resolvedAnchorMs = anchorMs ?? resolveLaunchMotorAnchorMs();
    return LaunchMotorSelectionService.resolveMotorIndex(
      anchorMs: resolvedAnchorMs,
      bandMinutes: _feedLaunchMotorBandMinutes,
      minuteSets: _feedLaunchMotorMinuteSets,
    );
  }

  List<int> resolveLaunchMotorOwnedMinutes({int? anchorMs}) {
    final resolvedAnchorMs = anchorMs ?? resolveLaunchMotorAnchorMs();
    return LaunchMotorSelectionService.resolveOwnedMinutes(
      anchorMs: resolvedAnchorMs,
      bandMinutes: _feedLaunchMotorBandMinutes,
      minuteSets: _feedLaunchMotorMinuteSets,
    );
  }

  List<PostsModel> buildLaunchMotorPool({
    required List<PostsModel> primaryCandidates,
    required List<PostsModel> fallbackCandidates,
    required int targetCount,
    bool allowSparseSlotFallback = false,
    bool emitLaunchMotorDiagnostics = true,
  }) {
    return _buildLatestOrderedItems(
      primaryCandidates: primaryCandidates,
      fallbackCandidates: fallbackCandidates,
      targetCount: targetCount,
      allowSparseSlotFallback: allowSparseSlotFallback,
      emitLaunchMotorDiagnostics: emitLaunchMotorDiagnostics,
    );
  }

  AgendaFeedPageApplyPlan buildPageApplyPlan({
    required List<PostsModel> currentItems,
    required List<PostsModel> pageItems,
    required int nowMs,
    required int loadLimit,
    required DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    required bool usesPrimaryFeed,
    int? maxItemsToAdd,
    bool pageItemsPreplanned = false,
  }) {
    final existingIds = currentItems.map((post) => post.docID).toSet();
    final arrangedPageItems = pageItemsPreplanned
        ? _normalizeFeedDisplayOrder(pageItems)
        : buildPlannerPageItems(
            pageItems,
            currentItemCount: currentItems.length,
          );
    final itemsToAdd = <PostsModel>[];
    final freshScheduledIds = <String>[];
    final tenMinAgo = nowMs - const Duration(minutes: 15).inMilliseconds;
    final cappedAddCount =
        maxItemsToAdd != null && maxItemsToAdd > 0 ? maxItemsToAdd : null;

    for (final post in arrangedPageItems) {
      if (existingIds.contains(post.docID)) {
        continue;
      }
      itemsToAdd.add(post);
      final justBecameVisible =
          post.timeStamp != 0 && post.timeStamp >= tenMinAgo;
      if (justBecameVisible) {
        freshScheduledIds.add(post.docID);
      }
      if (cappedAddCount != null && itemsToAdd.length >= cappedAddCount) {
        break;
      }
    }

    return AgendaFeedPageApplyPlan(
      itemsToAdd: itemsToAdd,
      freshScheduledIds: freshScheduledIds,
      hasMore: lastDoc != null && pageItems.length >= loadLimit,
      lastDoc: lastDoc,
      usesPrimaryFeed: usesPrimaryFeed,
      pageItemsPreplanned: pageItemsPreplanned,
    );
  }

  List<Map<String, dynamic>> capStartupRenderEntries({
    required List<Map<String, dynamic>> renderEntries,
    required int visiblePostCount,
  }) {
    if (renderEntries.isEmpty || visiblePostCount <= 0) {
      return const <Map<String, dynamic>>[];
    }
    var shownPostCount = 0;
    final capped = <Map<String, dynamic>>[];
    for (final entry in renderEntries) {
      final renderType = (entry['renderType'] ?? 'post').toString();
      if (renderType == 'promo') {
        if (shownPostCount > 0 && shownPostCount <= visiblePostCount) {
          capped.add(entry);
        }
        continue;
      }
      if (shownPostCount >= visiblePostCount) {
        break;
      }
      shownPostCount++;
      capped.add(entry);
    }
    return capped;
  }

  AgendaFeedRefreshPlan buildRefreshPlan({
    required List<PostsModel> currentItems,
    required List<PostsModel> fetchedPosts,
    required int nowMs,
  }) {
    if (fetchedPosts.isEmpty) {
      return AgendaFeedRefreshPlan(
        replacementItems: currentItems,
        freshScheduledIds: const <String>[],
      );
    }

    final existingIds = currentItems.map((post) => post.docID).toSet();
    final orderedFetchedPosts = _normalizeFeedDisplayOrder(fetchedPosts);
    final fetchedById = <String, PostsModel>{
      for (final post in orderedFetchedPosts) post.docID: post,
    };
    final freshScheduledIds = <String>[];
    final fifteenMinAgo = nowMs - const Duration(minutes: 15).inMilliseconds;
    final newHeadItems = <PostsModel>[];

    for (final post in orderedFetchedPosts) {
      if (existingIds.contains(post.docID)) {
        continue;
      }
      newHeadItems.add(post);
      final justBecameVisible =
          post.timeStamp != 0 && post.timeStamp >= fifteenMinAgo;
      if (justBecameVisible) {
        freshScheduledIds.add(post.docID);
      }
    }

    final replacementItems = <PostsModel>[];
    final seenIds = <String>{};

    for (final post in newHeadItems) {
      if (seenIds.add(post.docID)) {
        replacementItems.add(post);
      }
    }

    for (final post in currentItems) {
      final replacement = fetchedById[post.docID] ?? post;
      if (seenIds.add(replacement.docID)) {
        replacementItems.add(replacement);
      }
    }

    return AgendaFeedRefreshPlan(
      replacementItems: replacementItems,
      freshScheduledIds: freshScheduledIds,
    );
  }

  List<PostsModel> buildStartupPlannerHead({
    required List<PostsModel> liveCandidates,
    required List<PostsModel> cacheCandidates,
    required int targetCount,
    int? startupVariantOverride,
    Set<String>? cacheReadyVideoDocIds,
    bool allowSparseSlotFallback = false,
    bool emitLaunchMotorDiagnostics = true,
  }) {
    if (targetCount <= 0) return const <PostsModel>[];
    final startupVariant = startupVariantOverride ??
        startupVariantIndexForSurface(
          surfaceKey: 'feed_startup_head',
          sessionNamespace: 'feed',
          variantCount: 997,
        );
    return _composeFeedItems(
      liveCandidates: liveCandidates,
      cacheCandidates: cacheCandidates,
      targetCount: targetCount,
      variantSeed: startupVariant,
      includeStartupHeadPenalty: true,
      allowSparseSlotFallback: allowSparseSlotFallback,
      cacheReadyVideoDocIds: cacheReadyVideoDocIds,
      emitLaunchMotorDiagnostics: emitLaunchMotorDiagnostics,
    );
  }

  List<PostsModel> mergeLiveItemsPreservingCurrentOrder({
    required List<PostsModel> currentItems,
    required List<PostsModel> liveItems,
    bool liveItemsPreplanned = false,
  }) {
    if (currentItems.isEmpty) {
      final arrangedLiveItems = liveItemsPreplanned
          ? _normalizeFeedDisplayOrder(liveItems)
          : buildPlannerPageItems(
              liveItems,
              currentItemCount: 0,
            );
      return _normalizeFeedDisplayOrder(arrangedLiveItems);
    }
    if (liveItems.isEmpty) {
      return currentItems;
    }

    final arrangedLiveItems = liveItemsPreplanned
        ? _normalizeFeedDisplayOrder(liveItems)
        : buildPlannerPageItems(
            liveItems,
            currentItemCount: currentItems.length,
          );
    final liveById = <String, PostsModel>{
      for (final post in arrangedLiveItems)
        if (post.docID.trim().isNotEmpty) post.docID.trim(): post,
    };
    final merged = <PostsModel>[];
    final seenIds = <String>{};

    for (final current in currentItems) {
      final currentDocId = current.docID.trim();
      if (currentDocId.isEmpty) continue;
      final replacement = liveById[currentDocId] ?? current;
      final replacementDocId = replacement.docID.trim();
      if (replacementDocId.isEmpty || !seenIds.add(replacementDocId)) {
        continue;
      }
      merged.add(replacement);
    }

    for (final live in arrangedLiveItems) {
      final liveDocId = live.docID.trim();
      if (liveDocId.isEmpty || !seenIds.add(liveDocId)) continue;
      merged.add(live);
    }

    return _normalizeFeedDisplayOrder(merged);
  }

  List<PostsModel> buildPlannerPageItems(
    List<PostsModel> pageItems, {
    required int currentItemCount,
  }) {
    return _normalizeFeedDisplayOrder(pageItems);
  }

  List<PostsModel> buildPlannerSlice(
    List<PostsModel> candidates, {
    required int currentItemCount,
    required int targetCount,
    required bool includeStartupHeadPenalty,
    required bool allowSparseSlotFallback,
    bool emitLaunchMotorDiagnostics = true,
  }) {
    if (targetCount <= 0 || candidates.isEmpty) {
      return const <PostsModel>[];
    }
    if (candidates.length < 2) {
      return candidates.take(targetCount).toList(growable: false);
    }

    final pageOrdinal = currentItemCount < 0
        ? 0
        : currentItemCount ~/ FeedRenderBlockPlan.postSlotPlan.length;
    final variant = startupVariantIndexForSurface(
      surfaceKey: 'feed_page_mix_$pageOrdinal',
      sessionNamespace: 'feed',
      variantCount: 997,
    );
    return _composeFeedItems(
      liveCandidates: candidates,
      cacheCandidates: const <PostsModel>[],
      targetCount: targetCount,
      variantSeed: variant,
      includeStartupHeadPenalty: includeStartupHeadPenalty,
      allowSparseSlotFallback: allowSparseSlotFallback,
      emitLaunchMotorDiagnostics: emitLaunchMotorDiagnostics,
    );
  }

  String? capturePlaybackAnchor({
    required List<PostsModel> agendaList,
    required int centeredIndex,
    required int? lastCenteredIndex,
  }) {
    if (centeredIndex >= 0 && centeredIndex < agendaList.length) {
      return agendaList[centeredIndex].docID;
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex >= 0 &&
        lastCenteredIndex < agendaList.length) {
      return agendaList[lastCenteredIndex].docID;
    }
    return null;
  }

  int resolveInitialCenteredIndex({
    required List<PostsModel> agendaList,
    required String? pendingCenteredDocId,
    required int? lastCenteredIndex,
    required bool Function(PostsModel post) canAutoplayPost,
  }) {
    if (agendaList.isEmpty) return -1;

    final pendingDocIndex =
        _resolvePendingCenteredDocIndex(agendaList, pendingCenteredDocId);
    if (pendingDocIndex >= 0) {
      return pendingDocIndex;
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex >= 0 &&
        lastCenteredIndex < agendaList.length) {
      return lastCenteredIndex;
    }
    return 0;
  }

  int resolveResumeIndex({
    required List<PostsModel> agendaList,
    required String? pendingCenteredDocId,
    required int? lastCenteredIndex,
    required int centeredIndex,
    required Map<int, double> visibleFractions,
    required bool Function(PostsModel post) canAutoplayPost,
  }) {
    if (agendaList.isEmpty) return -1;

    final pendingDocIndex =
        _resolvePendingCenteredDocIndex(agendaList, pendingCenteredDocId);
    if (pendingDocIndex >= 0) {
      return pendingDocIndex;
    }

    var bestIndex = -1;
    var bestFraction = 0.0;
    visibleFractions.forEach((index, fraction) {
      if (index < 0 || index >= agendaList.length) return;
      if (fraction > bestFraction) {
        bestFraction = fraction;
        bestIndex = index;
      }
    });

    var target = -1;
    if (bestIndex >= 0) {
      target = bestIndex;
    } else if (lastCenteredIndex != null &&
        lastCenteredIndex >= 0 &&
        lastCenteredIndex < agendaList.length) {
      target = lastCenteredIndex;
    } else if (centeredIndex >= 0 && centeredIndex < agendaList.length) {
      target = centeredIndex;
    } else {
      target = 0;
    }

    if (target < 0 || target >= agendaList.length) {
      target = 0;
    }
    return target;
  }

  int _resolvePendingCenteredDocIndex(
    List<PostsModel> agendaList,
    String? pendingCenteredDocId,
  ) {
    final pendingDocId = pendingCenteredDocId?.trim() ?? '';
    if (pendingDocId.isEmpty) return -1;
    return agendaList.indexWhere((post) => post.docID == pendingDocId);
  }

  List<PostsModel> _composeFeedItems({
    required List<PostsModel> liveCandidates,
    required List<PostsModel> cacheCandidates,
    required int targetCount,
    required int variantSeed,
    required bool includeStartupHeadPenalty,
    required bool allowSparseSlotFallback,
    Set<String>? cacheReadyVideoDocIds,
    required bool emitLaunchMotorDiagnostics,
  }) {
    final latestLiveFirst = buildLaunchMotorPool(
      primaryCandidates: liveCandidates,
      fallbackCandidates: const <PostsModel>[],
      targetCount: targetCount,
      allowSparseSlotFallback: allowSparseSlotFallback,
      emitLaunchMotorDiagnostics: emitLaunchMotorDiagnostics,
    );
    if (latestLiveFirst.isNotEmpty) {
      return latestLiveFirst;
    }
    return const <PostsModel>[];
  }

  List<PostsModel> _buildLatestOrderedItems({
    required List<PostsModel> primaryCandidates,
    required List<PostsModel> fallbackCandidates,
    required int targetCount,
    required bool allowSparseSlotFallback,
    required bool emitLaunchMotorDiagnostics,
  }) {
    if (targetCount <= 0) {
      return const <PostsModel>[];
    }
    final latestPool = _dedupePosts(primaryCandidates).toList(growable: true)
      ..sort(_compareLatestPosts);
    if (latestPool.isEmpty) {
      return const <PostsModel>[];
    }

    final launchMotorOrdered = _buildLaunchMotorOrderedItems(
      latestPool,
      targetCount: targetCount,
      allowSparseSlotFallback: allowSparseSlotFallback,
      emitLaunchMotorDiagnostics: emitLaunchMotorDiagnostics,
    );
    if (emitLaunchMotorDiagnostics) {
      debugPrint(
        '[FeedLaunchMotor] status=applied targetCount=$targetCount '
        'orderedCount=${launchMotorOrdered.length} '
        'sample=${launchMotorOrdered.take(5).map((post) => post.docID).join(",")}',
      );
    }
    return launchMotorOrdered;
  }

  List<PostsModel> _buildLaunchMotorOrderedItems(
    List<PostsModel> latestPool, {
    required int targetCount,
    required bool allowSparseSlotFallback,
    required bool emitLaunchMotorDiagnostics,
  }) {
    if (latestPool.isEmpty || targetCount <= 0) {
      return const <PostsModel>[];
    }

    final snapshot = LaunchMotorSelectionService.analyzePool(
      latestPool: latestPool,
      anchorMs: resolveLaunchMotorAnchorMs(),
      window: _feedLaunchMotorWindow,
      bandMinutes: _feedLaunchMotorBandMinutes,
      subsliceMs: _feedLaunchMotorSubsliceMs,
      minuteSets: _feedLaunchMotorMinuteSets,
    );
    if (snapshot.normalizedPool.isEmpty) {
      return const <PostsModel>[];
    }
    if (snapshot.windowedPool.isEmpty) {
      if (allowSparseSlotFallback) {
        final ownedMinuteBackfill = _backfillOwnedMinuteCandidates(
          latestPool: snapshot.normalizedPool,
          launchAnchorMs: snapshot.anchorMs,
          launchMotorIndex: snapshot.motorIndex,
          targetCount: targetCount,
        );
        if (ownedMinuteBackfill.isNotEmpty) {
          if (emitLaunchMotorDiagnostics) {
            debugPrint(
              '[FeedLaunchMotor] status=owned_minute_backfill_window_empty '
              'anchor=${snapshot.anchor.toIso8601String()} motor=${snapshot.motorIndex} '
              'subslice=${snapshot.subsliceIndex} orderedCount=${ownedMinuteBackfill.length} '
              'sample=${ownedMinuteBackfill.take(5).map((post) => post.docID).join(",")}',
            );
          }
          return ownedMinuteBackfill;
        }
      }
      if (emitLaunchMotorDiagnostics) {
        debugPrint(
          '[FeedLaunchMotor] status=empty_window_all_pool '
          'anchor=${snapshot.anchor.toIso8601String()} motor=${snapshot.motorIndex} '
          'subslice=${snapshot.subsliceIndex} pool=${snapshot.normalizedPool.length}',
        );
      }
      return const <PostsModel>[];
    }
    if (!snapshot.hasQueues) {
      if (allowSparseSlotFallback) {
        final ownedMinuteBackfill = _backfillOwnedMinuteCandidates(
          latestPool: snapshot.normalizedPool,
          launchAnchorMs: snapshot.anchorMs,
          launchMotorIndex: snapshot.motorIndex,
          targetCount: targetCount,
        );
        if (ownedMinuteBackfill.isNotEmpty) {
          if (emitLaunchMotorDiagnostics) {
            debugPrint(
              '[FeedLaunchMotor] status=owned_minute_backfill_no_queues '
              'anchor=${snapshot.anchor.toIso8601String()} motor=${snapshot.motorIndex} '
              'subslice=${snapshot.subsliceIndex} orderedCount=${ownedMinuteBackfill.length} '
              'sample=${ownedMinuteBackfill.take(5).map((post) => post.docID).join(",")}',
            );
          }
          return ownedMinuteBackfill;
        }
      }
      if (emitLaunchMotorDiagnostics) {
        debugPrint(
          '[FeedLaunchMotor] status=no_queues_strict '
          'anchor=${snapshot.anchor.toIso8601String()} motor=${snapshot.motorIndex} '
          'subslice=${snapshot.subsliceIndex} pool=${snapshot.windowedPool.length}',
        );
      }
      return const <PostsModel>[];
    }

    if (emitLaunchMotorDiagnostics) {
      debugPrint(
        '[FeedLaunchMotor] status=queues_ready '
        'anchor=${snapshot.anchor.toIso8601String()} motor=${snapshot.motorIndex} '
        'subslice=${snapshot.subsliceIndex} pool=${snapshot.windowedPool.length} '
        'queues=${snapshot.queueCount}',
      );
    }

    // Keep feed motor strict once it found owned queues; do not backfill
    // non-owned candidates into the visible order.
    final strictSelection =
        snapshot.strictSelection.take(targetCount).toList(growable: false);
    if (!allowSparseSlotFallback || strictSelection.length >= targetCount) {
      return LaunchMotorSelectionService.sortLatestFirst(strictSelection);
    }

    final ownedMinuteBackfill = _backfillOwnedMinuteCandidates(
      latestPool: snapshot.normalizedPool,
      launchAnchorMs: snapshot.anchorMs,
      launchMotorIndex: snapshot.motorIndex,
      targetCount: targetCount - strictSelection.length,
      excludeDocIds: strictSelection.map((post) => post.docID.trim()).toSet(),
    );
    final combined = <PostsModel>[
      ...strictSelection,
      ...ownedMinuteBackfill,
    ];
    if (emitLaunchMotorDiagnostics) {
      debugPrint(
        '[FeedLaunchMotor] status=owned_minute_backfill_strict '
        'anchor=${snapshot.anchor.toIso8601String()} motor=${snapshot.motorIndex} '
        'subslice=${snapshot.subsliceIndex} strictCount=${strictSelection.length} '
        'backfillCount=${ownedMinuteBackfill.length} '
        'orderedCount=${combined.length}',
      );
    }
    return LaunchMotorSelectionService.sortLatestFirst(
      combined.take(targetCount).toList(growable: false),
    );
  }

  List<PostsModel> _backfillOwnedMinuteCandidates({
    required List<PostsModel> latestPool,
    required int launchAnchorMs,
    required int launchMotorIndex,
    required int targetCount,
    Set<String> excludeDocIds = const <String>{},
  }) {
    if (targetCount <= 0 || latestPool.isEmpty) {
      return const <PostsModel>[];
    }
    final ownedMinuteSet = _feedLaunchMotorMinuteSets[launchMotorIndex].toSet();
    final seenIds = excludeDocIds
        .where((docId) => docId.trim().isNotEmpty)
        .map((docId) => docId.trim())
        .toSet();
    final ownedCandidates = <PostsModel>[];
    for (final post in latestPool) {
      final docId = post.docID.trim();
      if (docId.isEmpty || seenIds.contains(docId)) {
        continue;
      }
      final timestampMs = post.timeStamp.toInt();
      if (timestampMs <= 0 || timestampMs > launchAnchorMs) {
        continue;
      }
      final minute = DateTime.fromMillisecondsSinceEpoch(timestampMs).minute;
      if (!ownedMinuteSet.contains(minute) || !seenIds.add(docId)) {
        continue;
      }
      ownedCandidates.add(post);
      if (ownedCandidates.length >= targetCount) {
        break;
      }
    }
    return LaunchMotorSelectionService.sortLatestFirst(ownedCandidates);
  }

  static int _defaultNowMsProvider() => DateTime.now().millisecondsSinceEpoch;

  List<PostsModel> _normalizeFeedDisplayOrder(List<PostsModel> items) {
    return LaunchMotorSelectionService.sortLatestFirst(
      _dedupePosts(items),
    );
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
      best = min(best, min(distance, wrappedDistance));
    }
    return best;
  }

  int _launchMotorSubsliceDistanceScore({
    required int timestampMs,
    required int preferredSubsliceIndex,
  }) {
    final currentSubslice =
        ((timestampMs % 1000) ~/ _feedLaunchMotorSubsliceMs).clamp(0, 4);
    return (currentSubslice - preferredSubsliceIndex).abs();
  }

  List<_FeedLaunchMinuteQueue> _buildLaunchMotorQueues({
    required List<PostsModel> candidates,
    required DateTime launchAnchor,
    required int launchWindowStartMs,
    required int launchMotorIndex,
  }) {
    final ownedMinutes = _feedLaunchMotorMinuteSets[launchMotorIndex]
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

    final queues = <_FeedLaunchMinuteQueue>[];
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
          _FeedLaunchMinuteQueue(
            anchorMs: queueAnchor,
            items: items,
          ),
        );
      }
      hourCursor = hourCursor.subtract(const Duration(hours: 1));
    }

    return queues;
  }

  int _compareLatestPosts(PostsModel left, PostsModel right) {
    final timeCompare = right.timeStamp.compareTo(left.timeStamp);
    if (timeCompare != 0) {
      return timeCompare;
    }
    return right.docID.trim().compareTo(left.docID.trim());
  }

  List<PostsModel> _prepareBucketCandidates(
    List<PostsModel> items, {
    required FeedPlannerPostBucket bucket,
    required int variantSeed,
    required _AgendaFeedPenaltySnapshot penalties,
  }) {
    if (items.length < 2) {
      return items.toList(growable: true);
    }

    final timeOrdered = items.toList(growable: true)
      ..sort((left, right) => right.timeStamp.compareTo(left.timeStamp));
    if (bucket == FeedPlannerPostBucket.live) {
      int compareLiveCandidates(PostsModel left, PostsModel right) {
        final timeCompare = right.timeStamp.compareTo(left.timeStamp);
        if (timeCompare != 0) {
          return timeCompare;
        }
        final leftPenalty = _candidatePenaltyScore(left, penalties);
        final rightPenalty = _candidatePenaltyScore(right, penalties);
        if (leftPenalty != rightPenalty) {
          return leftPenalty.compareTo(rightPenalty);
        }
        return left.docID.trim().compareTo(right.docID.trim());
      }

      final liveCutoffMs = DateTime.now().millisecondsSinceEpoch -
          _livePlannerWindow.inMilliseconds;
      final recent = <PostsModel>[];
      final older = <PostsModel>[];
      for (final post in timeOrdered) {
        if (post.timeStamp.toInt() >= liveCutoffMs) {
          recent.add(post);
        } else {
          older.add(post);
        }
      }
      recent.sort(compareLiveCandidates);
      older.sort(compareLiveCandidates);
      return <PostsModel>[
        ...recent,
        ...older,
      ];
    }

    final ranked = <PostsModel>[];
    for (var start = 0;
        start < timeOrdered.length;
        start += _feedPlannerShuffleWindow) {
      final end = (start + _feedPlannerShuffleWindow < timeOrdered.length)
          ? start + _feedPlannerShuffleWindow
          : timeOrdered.length;
      final chunk = timeOrdered.sublist(start, end)
        ..sort((left, right) {
          final leftPenalty = _candidatePenaltyScore(left, penalties);
          final rightPenalty = _candidatePenaltyScore(right, penalties);
          if (leftPenalty != rightPenalty) {
            return leftPenalty.compareTo(rightPenalty);
          }
          final leftRank = _bucketRankScore(
            left,
            bucket: bucket,
            variantSeed: variantSeed,
          );
          final rightRank = _bucketRankScore(
            right,
            bucket: bucket,
            variantSeed: variantSeed,
          );
          if (leftRank != rightRank) {
            return leftRank.compareTo(rightRank);
          }
          return right.timeStamp.compareTo(left.timeStamp);
        });
      ranked.addAll(
        reorderForStartupSurface(
          chunk,
          surfaceKey:
              'feed_bucket_${bucket.name}_${variantSeed}_${start ~/ _feedPlannerShuffleWindow}',
          sessionNamespace: 'feed',
          maxShuffleWindow: chunk.length,
        ),
      );
    }
    return ranked;
  }

  int _bucketRankScore(
    PostsModel post, {
    required FeedPlannerPostBucket bucket,
    required int variantSeed,
  }) {
    return Object.hash(
      variantSeed,
      bucket.index,
      post.docID.trim(),
      post.userID.trim(),
      post.timeStamp,
    ).abs();
  }

  int _candidatePenaltyScore(
    PostsModel post,
    _AgendaFeedPenaltySnapshot penalties,
  ) {
    final docId = post.docID.trim();
    final floodRootId = _resolveFloodRootId(post);
    var score = 0;
    if (docId.isNotEmpty && penalties.startupHeadDocIds.contains(docId)) {
      score += 6;
    }
    if (floodRootId.isNotEmpty &&
        penalties.startupHeadFloodRootIds.contains(floodRootId)) {
      score += 6;
    }
    if (docId.isNotEmpty && penalties.weeklyWatchedDocIds.contains(docId)) {
      score += 12;
    }
    if (floodRootId.isNotEmpty &&
        penalties.weeklyWatchedFloodRootIds.contains(floodRootId)) {
      score += 12;
    }
    return score;
  }

  _AgendaFeedPenaltySnapshot _capturePenaltySnapshot({
    required bool includeStartupHead,
  }) {
    final service = FeedDiversityMemoryService.maybeFind();
    if (service == null || !service.isReady) {
      return const _AgendaFeedPenaltySnapshot.empty();
    }
    return _AgendaFeedPenaltySnapshot(
      startupHeadDocIds:
          includeStartupHead ? service.startupHeadPenaltyDocIds() : const {},
      startupHeadFloodRootIds: includeStartupHead
          ? service.startupHeadPenaltyFloodRootIds()
          : const {},
      weeklyWatchedDocIds: service.weeklyWatchedPenaltyDocIds(),
      weeklyWatchedFloodRootIds: service.weeklyWatchedFloodRootIds(),
    );
  }

  String _resolveFloodRootId(PostsModel post) {
    if (!post.isFloodSeriesContent) return '';
    final mainFlood = post.mainFlood.trim();
    if (mainFlood.isNotEmpty) return mainFlood;
    if (post.isFloodSeriesRoot) return post.docID.trim();
    return post.docID.trim().replaceFirst(RegExp(r'_\d+$'), '');
  }

  List<FeedPlannerPostBucket> _slotFallbackOrder(
    FeedPlannerPostBucket desiredBucket, {
    required bool allowSparseSlotFallback,
  }) {
    late final List<FeedPlannerPostBucket> fallback;
    switch (desiredBucket) {
      case FeedPlannerPostBucket.cache:
        fallback = <FeedPlannerPostBucket>[
          FeedPlannerPostBucket.cache,
          FeedPlannerPostBucket.live,
        ];
        break;
      case FeedPlannerPostBucket.live:
        fallback = <FeedPlannerPostBucket>[
          FeedPlannerPostBucket.live,
        ];
        break;
      case FeedPlannerPostBucket.image:
        fallback = <FeedPlannerPostBucket>[
          FeedPlannerPostBucket.image,
          FeedPlannerPostBucket.flood,
        ];
        break;
      case FeedPlannerPostBucket.flood:
        fallback = <FeedPlannerPostBucket>[
          FeedPlannerPostBucket.flood,
        ];
        break;
      case FeedPlannerPostBucket.text:
        fallback = <FeedPlannerPostBucket>[
          FeedPlannerPostBucket.text,
          FeedPlannerPostBucket.live,
        ];
        break;
    }
    if (!allowSparseSlotFallback ||
        desiredBucket == FeedPlannerPostBucket.live ||
        desiredBucket == FeedPlannerPostBucket.cache ||
        fallback.contains(FeedPlannerPostBucket.live)) {
      return fallback;
    }
    return <FeedPlannerPostBucket>[
      ...fallback,
      FeedPlannerPostBucket.live,
    ];
  }

  PostsModel? _selectCandidateForSlot({
    required FeedPlannerPostBucket desiredBucket,
    required Map<FeedPlannerPostBucket, List<PostsModel>> buckets,
    required Set<String> usedIds,
    required _AgendaFeedPenaltySnapshot penalties,
    required bool preferStartupHeadExclusion,
    required bool allowSparseSlotFallback,
  }) {
    final fallbackOrder = _slotFallbackOrder(
      desiredBucket,
      allowSparseSlotFallback: allowSparseSlotFallback,
    );
    final fallbackBuckets = fallbackOrder.skip(1).toList(growable: false);

    PostsModel? pickFromBucket(
      FeedPlannerPostBucket bucket, {
      required bool excludeStartupHeadPenalty,
    }) {
      return _firstUnusedCandidate(
        buckets: buckets,
        usedIds: usedIds,
        bucket: bucket,
        penalties: penalties,
        excludeStartupHeadPenalty: excludeStartupHeadPenalty,
      );
    }

    if (preferStartupHeadExclusion) {
      final preferred = pickFromBucket(
        desiredBucket,
        excludeStartupHeadPenalty: true,
      );
      if (preferred != null) {
        return preferred;
      }
    }

    final desired = pickFromBucket(
      desiredBucket,
      excludeStartupHeadPenalty: false,
    );
    if (desired != null) {
      return desired;
    }

    if (preferStartupHeadExclusion) {
      for (final bucket in fallbackBuckets) {
        final fallback = pickFromBucket(
          bucket,
          excludeStartupHeadPenalty: true,
        );
        if (fallback != null) {
          return fallback;
        }
      }
    }

    for (final bucket in fallbackBuckets) {
      final fallback = pickFromBucket(
        bucket,
        excludeStartupHeadPenalty: false,
      );
      if (fallback != null) {
        return fallback;
      }
    }
    return null;
  }

  PostsModel? _firstUnusedCandidate({
    required Map<FeedPlannerPostBucket, List<PostsModel>> buckets,
    required Set<String> usedIds,
    required FeedPlannerPostBucket bucket,
    required _AgendaFeedPenaltySnapshot penalties,
    required bool excludeStartupHeadPenalty,
  }) {
    final items = buckets[bucket] ?? const <PostsModel>[];
    for (final post in items) {
      final docId = post.docID.trim();
      if (docId.isEmpty || usedIds.contains(docId)) {
        continue;
      }
      if (excludeStartupHeadPenalty &&
          _isStartupHeadPenaltyCandidate(post, penalties)) {
        continue;
      }
      return post;
    }
    return null;
  }

  bool _isStartupHeadPenaltyCandidate(
    PostsModel post,
    _AgendaFeedPenaltySnapshot penalties,
  ) {
    final docId = post.docID.trim();
    if (docId.isNotEmpty && penalties.startupHeadDocIds.contains(docId)) {
      return true;
    }
    final floodRootId = _resolveFloodRootId(post);
    if (floodRootId.isNotEmpty &&
        penalties.startupHeadFloodRootIds.contains(floodRootId)) {
      return true;
    }
    return false;
  }

  List<PostsModel> _dedupePosts(List<PostsModel> posts) {
    final seenIds = <String>{};
    final output = <PostsModel>[];
    for (final post in posts) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenIds.add(docId)) continue;
      output.add(post);
    }
    return output;
  }

  _AgendaStartupCandidateSplit _splitStartupCandidates({
    required List<PostsModel> liveCandidates,
    required List<PostsModel> cacheCandidates,
    required Set<String>? cacheReadyVideoDocIds,
  }) {
    if (cacheCandidates.isEmpty ||
        cacheReadyVideoDocIds == null ||
        cacheReadyVideoDocIds.isEmpty) {
      return _AgendaStartupCandidateSplit(
        cacheCandidates: cacheCandidates,
        liveCandidates: liveCandidates,
      );
    }
    return _AgendaStartupCandidateSplit(
      cacheCandidates: cacheCandidates,
      liveCandidates: liveCandidates,
    );
  }

  bool _isImageCandidate(PostsModel post) {
    if (post.isFloodSeriesContent || post.hasPlayableVideo) {
      return false;
    }
    return post.hasImageContent;
  }

  bool _isTextCandidate(PostsModel post) {
    if (post.isFloodSeriesContent || post.hasPlayableVideo) {
      return false;
    }
    if (!post.hasTextContent) {
      return false;
    }
    return !post.hasImageContent && post.thumbnail.trim().isEmpty;
  }

  List<FeedPlannerPostBucket> _postSlotPlanForTarget(int targetCount) {
    if (targetCount <= 0) return const <FeedPlannerPostBucket>[];
    final slotPlan = <FeedPlannerPostBucket>[];
    while (slotPlan.length < targetCount) {
      final remaining = targetCount - slotPlan.length;
      slotPlan.addAll(
        FeedRenderBlockPlan.postSlotPlan.take(
          remaining < FeedRenderBlockPlan.postSlotPlan.length
              ? remaining
              : FeedRenderBlockPlan.postSlotPlan.length,
        ),
      );
    }
    return slotPlan;
  }
}

class _AgendaStartupCandidateSplit {
  const _AgendaStartupCandidateSplit({
    required this.cacheCandidates,
    required this.liveCandidates,
  });

  final List<PostsModel> cacheCandidates;
  final List<PostsModel> liveCandidates;
}

class _FeedLaunchMinuteQueue {
  _FeedLaunchMinuteQueue({
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
