import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Services/feed_diversity_memory_service.dart';
import 'package:turqappv2/Core/Services/startup_surface_order_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

enum _AgendaStartupBucket {
  cacheVideo,
  liveVideo,
  image,
  flood,
  text,
}

enum _AgendaPresentationBucket {
  video,
  image,
  flood,
  text,
}

class AgendaFeedPageApplyPlan {
  const AgendaFeedPageApplyPlan({
    required this.itemsToAdd,
    required this.freshScheduledIds,
    required this.hasMore,
    required this.lastDoc,
    required this.usesPrimaryFeed,
  });

  final List<PostsModel> itemsToAdd;
  final List<String> freshScheduledIds;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool usesPrimaryFeed;
}

class AgendaFeedRefreshPlan {
  const AgendaFeedRefreshPlan({
    required this.replacementItems,
    required this.freshScheduledIds,
  });

  final List<PostsModel> replacementItems;
  final List<String> freshScheduledIds;
}

class AgendaFeedBufferedWindowPlan {
  const AgendaFeedBufferedWindowPlan({
    required this.blockBaseCount,
    required this.targetAgendaCount,
    required this.startsNewBlock,
  });

  final int blockBaseCount;
  final int targetAgendaCount;
  final bool startsNewBlock;
}

class _AgendaPresentationSelection {
  const _AgendaPresentationSelection({
    required this.post,
    required this.bucket,
  });

  final PostsModel post;
  final _AgendaPresentationBucket bucket;
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

  bool get hasStartupPenalties =>
      startupHeadDocIds.isNotEmpty ||
      startupHeadFloodRootIds.isNotEmpty ||
      weeklyWatchedDocIds.isNotEmpty ||
      weeklyWatchedFloodRootIds.isNotEmpty;

  bool get hasPresentationPenalties =>
      weeklyWatchedDocIds.isNotEmpty || weeklyWatchedFloodRootIds.isNotEmpty;
}

class AgendaFeedApplicationService {
  static const List<_AgendaStartupBucket> _startupPreferredPostSlotPlan =
      <_AgendaStartupBucket>[
    _AgendaStartupBucket.cacheVideo,
    _AgendaStartupBucket.cacheVideo,
    _AgendaStartupBucket.image,
    _AgendaStartupBucket.liveVideo,
    _AgendaStartupBucket.liveVideo,
    _AgendaStartupBucket.flood,
    _AgendaStartupBucket.liveVideo,
    _AgendaStartupBucket.cacheVideo,
    _AgendaStartupBucket.text,
    _AgendaStartupBucket.liveVideo,
    _AgendaStartupBucket.liveVideo,
    _AgendaStartupBucket.image,
    _AgendaStartupBucket.cacheVideo,
    _AgendaStartupBucket.liveVideo,
    _AgendaStartupBucket.flood,
  ];

  static const List<_AgendaPresentationBucket> _feedPresentationPostSlotPlan =
      <_AgendaPresentationBucket>[
    _AgendaPresentationBucket.video,
    _AgendaPresentationBucket.video,
    _AgendaPresentationBucket.image,
    _AgendaPresentationBucket.video,
    _AgendaPresentationBucket.video,
    _AgendaPresentationBucket.flood,
    _AgendaPresentationBucket.video,
    _AgendaPresentationBucket.video,
    _AgendaPresentationBucket.text,
    _AgendaPresentationBucket.video,
    _AgendaPresentationBucket.video,
    _AgendaPresentationBucket.image,
    _AgendaPresentationBucket.video,
    _AgendaPresentationBucket.video,
    _AgendaPresentationBucket.flood,
  ];

  static const int _feedPresentationShuffleWindow = 24;

  AgendaFeedPageApplyPlan buildPageApplyPlan({
    required List<PostsModel> currentItems,
    required List<PostsModel> pageItems,
    required int nowMs,
    required int loadLimit,
    required DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    required bool usesPrimaryFeed,
  }) {
    final existingIds = currentItems.map((post) => post.docID).toSet();
    final arrangedPageItems = mixFeedPageItems(
      pageItems,
      currentItemCount: currentItems.length,
    );
    final itemsToAdd = <PostsModel>[];
    final freshScheduledIds = <String>[];
    final tenMinAgo = nowMs - const Duration(minutes: 15).inMilliseconds;

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
    }

    return AgendaFeedPageApplyPlan(
      itemsToAdd: itemsToAdd,
      freshScheduledIds: freshScheduledIds,
      hasMore: lastDoc != null && pageItems.length >= loadLimit,
      lastDoc: lastDoc,
      usesPrimaryFeed: usesPrimaryFeed,
    );
  }

  int resolveNextBufferedFetchTrigger({
    required int currentTrigger,
    required int viewedCount,
    required int stride,
  }) {
    if (stride <= 0) return currentTrigger;
    var nextTrigger = currentTrigger;
    while (nextTrigger <= viewedCount) {
      nextTrigger += stride;
    }
    return nextTrigger;
  }

  AgendaFeedBufferedWindowPlan? resolveBufferedWindowPlan({
    required int viewedCount,
    required int initialCount,
    required int blockSize,
    required int stepSize,
  }) {
    if (viewedCount < stepSize ||
        initialCount <= 0 ||
        blockSize <= 0 ||
        stepSize <= 0) {
      return null;
    }

    final normalizedViewedCount = viewedCount - stepSize;
    final blockOffset = (normalizedViewedCount ~/ blockSize) * blockSize;
    final blockBaseCount = initialCount + blockOffset;
    final revealStepIndex =
        ((normalizedViewedCount % blockSize) ~/ stepSize) + 1;
    final targetAgendaCount = blockBaseCount + (revealStepIndex * stepSize);

    return AgendaFeedBufferedWindowPlan(
      blockBaseCount: blockBaseCount,
      targetAgendaCount: targetAgendaCount,
      startsNewBlock: revealStepIndex == 1,
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
    final fetchedById = <String, PostsModel>{
      for (final post in fetchedPosts) post.docID: post,
    };
    final freshScheduledIds = <String>[];
    final fifteenMinAgo = nowMs - const Duration(minutes: 15).inMilliseconds;
    final newHeadItems = <PostsModel>[];

    for (final post in fetchedPosts) {
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

  List<PostsModel> composeStartupFeedItems({
    required List<PostsModel> liveCandidates,
    required List<PostsModel> cacheCandidates,
    required int targetCount,
    int? startupVariantOverride,
    Set<String>? cacheReadyVideoDocIds,
    bool allowSparseSlotFallback = false,
  }) {
    if (targetCount <= 0) return const <PostsModel>[];

    final split = _splitStartupCandidates(
      liveCandidates: liveCandidates,
      cacheCandidates: cacheCandidates,
      cacheReadyVideoDocIds: cacheReadyVideoDocIds,
    );
    final penaltySnapshot = _capturePenaltySnapshot();
    final normalizedLive = _dedupePosts(split.liveCandidates);
    final normalizedCache = _dedupePosts(split.cacheCandidates);
    final liveById = <String, PostsModel>{
      for (final post in normalizedLive) post.docID.trim(): post,
    };
    final normalizedSupport = _dedupePosts(<PostsModel>[
      ...normalizedCache,
      ...normalizedLive,
    ]);
    final buckets = <_AgendaStartupBucket, List<PostsModel>>{
      _AgendaStartupBucket.cacheVideo: normalizedCache
          .where(
            (post) => post.hasPlayableVideo && !post.isFloodSeriesContent,
          )
          .toList(growable: true),
      _AgendaStartupBucket.liveVideo: normalizedLive
          .where(
            (post) => post.hasPlayableVideo && !post.isFloodSeriesContent,
          )
          .toList(growable: true),
      _AgendaStartupBucket.image: normalizedSupport
          .where(_isImageStartupCandidate)
          .toList(growable: true),
      _AgendaStartupBucket.flood:
          normalizedSupport.where(_isFloodFeedCandidate).toList(growable: true),
      _AgendaStartupBucket.text: normalizedSupport
          .where(_isTextStartupCandidate)
          .toList(growable: true),
    };

    final slotPlan = _startupSlotPlanForTarget(targetCount);
    if (startupVariantOverride != null) {
      for (final entry in buckets.entries) {
        final prepared = _prepareStartupBucketCandidates(
          entry.value.toList(growable: false),
          bucket: entry.key,
          startupVariantOverride: startupVariantOverride,
          penaltySnapshot: penaltySnapshot,
        );
        entry.value
          ..clear()
          ..addAll(prepared);
      }
    }

    final output = <PostsModel>[];
    final usedIds = <String>{};
    for (var start = 0;
        start < slotPlan.length;
        start += _startupPreferredPostSlotPlan.length) {
      final end =
          (start + _startupPreferredPostSlotPlan.length < slotPlan.length)
              ? start + _startupPreferredPostSlotPlan.length
              : slotPlan.length;
      output.addAll(
        _composeStartupSlotChunk(
          slotPlan: slotPlan.sublist(start, end),
          buckets: buckets,
          usedIds: usedIds,
          allowSparseSlotFallback: allowSparseSlotFallback,
        ),
      );
      if (output.length >= targetCount) break;
    }

    return output
        .take(targetCount)
        .map((post) => liveById[post.docID.trim()] ?? post)
        .toList(growable: false);
  }

  List<PostsModel> mergeStartupHeadWithCurrentItems({
    required List<PostsModel> currentItems,
    required List<PostsModel> liveItems,
    required int targetCount,
    required int nowMs,
    int? startupVariantOverride,
    Set<String>? cacheReadyVideoDocIds,
    bool preferLiveStartupHead = false,
  }) {
    final refreshPlan = buildRefreshPlan(
      currentItems: currentItems,
      fetchedPosts: liveItems,
      nowMs: nowMs,
    );
    final effectivePreferLiveStartupHead = preferLiveStartupHead &&
        shouldPreferLiveStartupHeadForMerge(
          currentItems: currentItems,
          liveItems: liveItems,
          targetCount: targetCount,
        );
    final startupHead = composeStartupFeedItems(
      liveCandidates: liveItems,
      cacheCandidates:
          effectivePreferLiveStartupHead ? const <PostsModel>[] : currentItems,
      targetCount: targetCount,
      startupVariantOverride: startupVariantOverride,
      cacheReadyVideoDocIds: cacheReadyVideoDocIds,
    );
    final startupHeadIds = startupHead.map((post) => post.docID).toSet();
    return <PostsModel>[
      ...startupHead,
      ...refreshPlan.replacementItems
          .where((post) => !startupHeadIds.contains(post.docID)),
    ];
  }

  Map<String, int> startupSupportTargetsForCount(int targetCount) {
    final targets = _startupSupportTargetsForTarget(targetCount);
    return <String, int>{
      'flood': targets[_AgendaStartupBucket.flood] ?? 0,
      'image': targets[_AgendaStartupBucket.image] ?? 0,
      'text': targets[_AgendaStartupBucket.text] ?? 0,
    };
  }

  bool shouldPreferLiveStartupHeadForMerge({
    required List<PostsModel> currentItems,
    required List<PostsModel> liveItems,
    required int targetCount,
  }) {
    if (targetCount <= 0 || currentItems.isEmpty || liveItems.isEmpty) {
      return true;
    }

    final currentDeficitScore = _startupSupportDeficitScore(
      currentItems.take(targetCount),
      targetCount: targetCount,
    );
    final liveOnlyHead = composeStartupFeedItems(
      liveCandidates: liveItems,
      cacheCandidates: const <PostsModel>[],
      targetCount: targetCount,
    );
    if (liveOnlyHead.length < targetCount) {
      return false;
    }
    final liveDeficitScore = _startupSupportDeficitScore(
      liveOnlyHead,
      targetCount: targetCount,
    );
    return liveDeficitScore <= currentDeficitScore;
  }

  List<PostsModel> _prepareStartupBucketCandidates(
    List<PostsModel> items, {
    required _AgendaStartupBucket bucket,
    required int startupVariantOverride,
    required _AgendaFeedPenaltySnapshot penaltySnapshot,
  }) {
    if (items.length < 2) {
      return items;
    }
    final timeOrdered = items.toList(growable: true)
      ..sort((left, right) => right.timeStamp.compareTo(left.timeStamp));
    final ranked = <PostsModel>[];
    for (var start = 0;
        start < timeOrdered.length;
        start += _feedPresentationShuffleWindow) {
      final end = (start + _feedPresentationShuffleWindow < timeOrdered.length)
          ? start + _feedPresentationShuffleWindow
          : timeOrdered.length;
      final chunk = timeOrdered.sublist(start, end)
        ..sort((left, right) {
          final leftScore = _startupBucketRankScore(
            left,
            bucket: bucket,
            startupVariantOverride: startupVariantOverride,
          );
          final rightScore = _startupBucketRankScore(
            right,
            bucket: bucket,
            startupVariantOverride: startupVariantOverride,
          );
          if (leftScore != rightScore) {
            return leftScore.compareTo(rightScore);
          }
          return right.timeStamp.compareTo(left.timeStamp);
        });
      final reordered = reorderForStartupSurface(
        chunk,
        surfaceKey:
            'feed_startup_bucket_${bucket.index}_${startupVariantOverride}_${start ~/ _feedPresentationShuffleWindow}',
        sessionNamespace: 'feed',
        maxShuffleWindow: chunk.length,
      );
      ranked.addAll(
        _applyStartupPenaltyOrder(
          reordered,
          penaltySnapshot: penaltySnapshot,
        ),
      );
    }
    return ranked;
  }

  int _startupBucketRankScore(
    PostsModel post, {
    required _AgendaStartupBucket bucket,
    required int startupVariantOverride,
  }) {
    return Object.hash(
      startupVariantOverride,
      bucket.index,
      post.docID.trim(),
      post.userID.trim(),
      post.timeStamp,
    ).abs();
  }

  List<PostsModel> mixFeedPageItems(
    List<PostsModel> pageItems, {
    required int currentItemCount,
  }) {
    if (pageItems.length < 3) {
      return pageItems;
    }

    final pageOrdinal = currentItemCount < 0
        ? 0
        : currentItemCount ~/ _feedPresentationPostSlotPlan.length;
    final penaltySnapshot = _capturePenaltySnapshot();
    final buckets = <_AgendaPresentationBucket, List<PostsModel>>{
      _AgendaPresentationBucket.video: _prepareFeedPresentationBucketCandidates(
        pageItems
            .where(
                (post) => post.hasPlayableVideo && !post.isFloodSeriesContent)
            .toList(growable: false),
        bucket: _AgendaPresentationBucket.video,
        pageOrdinal: pageOrdinal,
        penaltySnapshot: penaltySnapshot,
      ),
      _AgendaPresentationBucket.image: _prepareFeedPresentationBucketCandidates(
        pageItems.where(_isImageFeedPresentationCandidate).toList(
              growable: false,
            ),
        bucket: _AgendaPresentationBucket.image,
        pageOrdinal: pageOrdinal,
        penaltySnapshot: penaltySnapshot,
      ),
      _AgendaPresentationBucket.flood: _prepareFeedPresentationBucketCandidates(
        pageItems.where(_isFloodFeedCandidate).toList(
              growable: false,
            ),
        bucket: _AgendaPresentationBucket.flood,
        pageOrdinal: pageOrdinal,
        penaltySnapshot: penaltySnapshot,
      ),
      _AgendaPresentationBucket.text: _prepareFeedPresentationBucketCandidates(
        pageItems.where(_isTextFeedPresentationCandidate).toList(
              growable: false,
            ),
        bucket: _AgendaPresentationBucket.text,
        pageOrdinal: pageOrdinal,
        penaltySnapshot: penaltySnapshot,
      ),
    };

    final output = <PostsModel>[];
    final usedIds = <String>{};
    final slotPlan = _feedPresentationSlotPlanForTarget(pageItems.length);
    for (var start = 0;
        start < slotPlan.length;
        start += _feedPresentationPostSlotPlan.length) {
      final end =
          (start + _feedPresentationPostSlotPlan.length < slotPlan.length)
              ? start + _feedPresentationPostSlotPlan.length
              : slotPlan.length;
      output.addAll(
        _composeFeedPresentationSlotChunk(
          slotPlan: slotPlan.sublist(start, end),
          buckets: buckets,
          usedIds: usedIds,
        ),
      );
      if (output.length >= pageItems.length) {
        return output.take(pageItems.length).toList(growable: false);
      }
    }

    for (final bucket in _AgendaPresentationBucket.values) {
      for (final post in buckets[bucket]!) {
        final docId = post.docID.trim();
        if (docId.isEmpty || !usedIds.add(docId)) continue;
        output.add(post);
        if (output.length >= pageItems.length) {
          return output;
        }
      }
    }

    return output.isEmpty ? pageItems : output;
  }

  List<PostsModel> _prepareFeedPresentationBucketCandidates(
    List<PostsModel> items, {
    required _AgendaPresentationBucket bucket,
    required int pageOrdinal,
    required _AgendaFeedPenaltySnapshot penaltySnapshot,
  }) {
    if (items.length < 2) {
      return items.toList(growable: true);
    }

    final timeOrdered = items.toList(growable: true)
      ..sort((left, right) => right.timeStamp.compareTo(left.timeStamp));
    final ranked = <PostsModel>[];
    for (var start = 0;
        start < timeOrdered.length;
        start += _feedPresentationShuffleWindow) {
      final end = (start + _feedPresentationShuffleWindow < timeOrdered.length)
          ? start + _feedPresentationShuffleWindow
          : timeOrdered.length;
      final chunk = timeOrdered.sublist(start, end)
        ..sort((left, right) {
          final leftScore = _feedPresentationBucketRankScore(
            left,
            bucket: bucket,
            pageOrdinal: pageOrdinal,
          );
          final rightScore = _feedPresentationBucketRankScore(
            right,
            bucket: bucket,
            pageOrdinal: pageOrdinal,
          );
          if (leftScore != rightScore) {
            return leftScore.compareTo(rightScore);
          }
          return right.timeStamp.compareTo(left.timeStamp);
        });
      final reordered = reorderForStartupSurface(
        chunk,
        surfaceKey:
            'feed_page_bucket_${bucket.index}_${pageOrdinal}_${start ~/ _feedPresentationShuffleWindow}',
        sessionNamespace: 'feed',
        maxShuffleWindow: chunk.length,
      );
      ranked.addAll(
        _applyPresentationPenaltyOrder(
          reordered,
          penaltySnapshot: penaltySnapshot,
        ),
      );
    }
    return ranked;
  }

  int _feedPresentationBucketRankScore(
    PostsModel post, {
    required _AgendaPresentationBucket bucket,
    required int pageOrdinal,
  }) {
    final variant = startupVariantIndexForSurface(
      surfaceKey: 'feed_page_mix_$pageOrdinal',
      sessionNamespace: 'feed',
      variantCount: 997,
    );
    return Object.hash(
      variant,
      pageOrdinal,
      bucket.index,
      post.docID.trim(),
      post.userID.trim(),
      post.timeStamp,
    ).abs();
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

  List<_AgendaPresentationBucket> _feedPresentationSlotPlanForTarget(
    int targetCount,
  ) {
    if (targetCount <= 0) return const <_AgendaPresentationBucket>[];
    final slotPlan = <_AgendaPresentationBucket>[];
    while (slotPlan.length < targetCount) {
      final remaining = targetCount - slotPlan.length;
      slotPlan.addAll(
        _feedPresentationPostSlotPlan.take(
          remaining < _feedPresentationPostSlotPlan.length
              ? remaining
              : _feedPresentationPostSlotPlan.length,
        ),
      );
    }
    return slotPlan;
  }

  List<_AgendaPresentationBucket> _feedPresentationSlotFallbackOrder(
    _AgendaPresentationBucket desiredBucket,
  ) {
    switch (desiredBucket) {
      case _AgendaPresentationBucket.video:
        return <_AgendaPresentationBucket>[
          _AgendaPresentationBucket.video,
        ];
      case _AgendaPresentationBucket.image:
        return <_AgendaPresentationBucket>[
          _AgendaPresentationBucket.image,
          _AgendaPresentationBucket.flood,
        ];
      case _AgendaPresentationBucket.flood:
        return <_AgendaPresentationBucket>[
          _AgendaPresentationBucket.flood,
        ];
      case _AgendaPresentationBucket.text:
        return <_AgendaPresentationBucket>[
          _AgendaPresentationBucket.text,
          _AgendaPresentationBucket.video,
        ];
    }
  }

  List<PostsModel> _composeFeedPresentationSlotChunk({
    required List<_AgendaPresentationBucket> slotPlan,
    required Map<_AgendaPresentationBucket, List<PostsModel>> buckets,
    required Set<String> usedIds,
  }) {
    if (slotPlan.isEmpty) return const <PostsModel>[];

    final output = <PostsModel>[];
    for (final desiredBucket in slotPlan) {
      final selection = _selectFeedPresentationCandidateForSlot(
        desiredBucket: desiredBucket,
        buckets: buckets,
        usedIds: usedIds,
      );
      if (selection == null) continue;
      final candidate = selection.post;
      final docId = candidate.docID.trim();
      if (docId.isEmpty || !usedIds.add(docId)) continue;
      output.add(candidate);
    }
    return output;
  }

  _AgendaPresentationSelection? _selectFeedPresentationCandidateForSlot({
    required _AgendaPresentationBucket desiredBucket,
    required Map<_AgendaPresentationBucket, List<PostsModel>> buckets,
    required Set<String> usedIds,
  }) {
    for (final bucket in _feedPresentationSlotFallbackOrder(desiredBucket)) {
      final candidate = _firstUnusedFeedPresentationCandidate(
        buckets[bucket]!,
        usedIds: usedIds,
      );
      if (candidate != null) {
        return _AgendaPresentationSelection(
          post: candidate,
          bucket: bucket,
        );
      }
    }
    return null;
  }

  PostsModel? _firstUnusedFeedPresentationCandidate(
    List<PostsModel> items, {
    required Set<String> usedIds,
  }) {
    for (final post in items) {
      final docId = post.docID.trim();
      if (docId.isEmpty || usedIds.contains(docId)) {
        continue;
      }
      return post;
    }
    return null;
  }

  List<_AgendaStartupBucket> _startupSlotFallbackOrder(
    _AgendaStartupBucket desiredBucket,
  ) {
    switch (desiredBucket) {
      case _AgendaStartupBucket.cacheVideo:
        return <_AgendaStartupBucket>[
          _AgendaStartupBucket.cacheVideo,
          _AgendaStartupBucket.liveVideo,
        ];
      case _AgendaStartupBucket.liveVideo:
        return <_AgendaStartupBucket>[
          _AgendaStartupBucket.liveVideo,
          _AgendaStartupBucket.cacheVideo,
        ];
      case _AgendaStartupBucket.image:
        return <_AgendaStartupBucket>[
          _AgendaStartupBucket.image,
          _AgendaStartupBucket.flood,
        ];
      case _AgendaStartupBucket.flood:
        return <_AgendaStartupBucket>[
          _AgendaStartupBucket.flood,
        ];
      case _AgendaStartupBucket.text:
        return <_AgendaStartupBucket>[
          _AgendaStartupBucket.text,
          _AgendaStartupBucket.liveVideo,
        ];
    }
  }

  List<PostsModel> _composeStartupSlotChunk({
    required List<_AgendaStartupBucket> slotPlan,
    required Map<_AgendaStartupBucket, List<PostsModel>> buckets,
    required Set<String> usedIds,
    required bool allowSparseSlotFallback,
  }) {
    if (slotPlan.isEmpty) return const <PostsModel>[];

    final output = <PostsModel>[];
    for (final desiredBucket in slotPlan) {
      final candidate = _selectStartupCandidateForSlot(
        desiredBucket: desiredBucket,
        buckets: buckets,
        usedIds: usedIds,
        allowSparseSlotFallback: allowSparseSlotFallback,
      );
      if (candidate == null) {
        if (!allowSparseSlotFallback) {
          break;
        }
        continue;
      }
      final docId = candidate.docID.trim();
      if (docId.isEmpty || !usedIds.add(docId)) {
        if (!allowSparseSlotFallback) {
          break;
        }
        continue;
      }
      output.add(candidate);
    }
    return output;
  }

  PostsModel? _selectStartupCandidateForSlot({
    required _AgendaStartupBucket desiredBucket,
    required Map<_AgendaStartupBucket, List<PostsModel>> buckets,
    required Set<String> usedIds,
    required bool allowSparseSlotFallback,
  }) {
    for (final bucket in _startupSlotFallbackOrder(desiredBucket)) {
      final candidate = _firstUnusedStartupCandidate(
        buckets[bucket]!,
        usedIds: usedIds,
      );
      if (candidate != null) {
        return candidate;
      }
    }
    if (!allowSparseSlotFallback) {
      return null;
    }
    return _selectSparseStartupFallbackCandidate(
      buckets,
      usedIds: usedIds,
    );
  }

  PostsModel? _selectSparseStartupFallbackCandidate(
    Map<_AgendaStartupBucket, List<PostsModel>> buckets, {
    required Set<String> usedIds,
  }) {
    const fallbackOrder = <_AgendaStartupBucket>[
      _AgendaStartupBucket.cacheVideo,
      _AgendaStartupBucket.liveVideo,
      _AgendaStartupBucket.image,
      _AgendaStartupBucket.flood,
      _AgendaStartupBucket.text,
    ];
    for (final bucket in fallbackOrder) {
      final candidate = _firstUnusedStartupCandidate(
        buckets[bucket]!,
        usedIds: usedIds,
      );
      if (candidate != null) {
        return candidate;
      }
    }
    return null;
  }

  PostsModel? _firstUnusedStartupCandidate(
    List<PostsModel> items, {
    required Set<String> usedIds,
  }) {
    for (final post in items) {
      final docId = post.docID.trim();
      if (docId.isEmpty || usedIds.contains(docId)) {
        continue;
      }
      return post;
    }
    return null;
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
    if (cacheCandidates.isEmpty || cacheReadyVideoDocIds == null) {
      return _AgendaStartupCandidateSplit(
        cacheCandidates: cacheCandidates,
        liveCandidates: liveCandidates,
      );
    }

    final normalizedCache = <PostsModel>[];
    final normalizedLive = <PostsModel>[
      ...liveCandidates,
    ];
    final normalizedReadyIds = cacheReadyVideoDocIds
        .map((docId) => docId.trim())
        .where((docId) => docId.isNotEmpty)
        .toSet();

    for (final post in cacheCandidates) {
      final docId = post.docID.trim();
      if (!post.hasPlayableVideo || normalizedReadyIds.contains(docId)) {
        normalizedCache.add(post);
      } else {
        normalizedLive.add(post);
      }
    }

    return _AgendaStartupCandidateSplit(
      cacheCandidates: normalizedCache,
      liveCandidates: normalizedLive,
    );
  }

  int _startupSupportDeficitScore(
    Iterable<PostsModel> posts, {
    required int targetCount,
  }) {
    if (targetCount < _startupPreferredPostSlotPlan.length) {
      return 0;
    }
    final counts = <_AgendaStartupBucket, int>{
      _AgendaStartupBucket.flood: 0,
      _AgendaStartupBucket.image: 0,
      _AgendaStartupBucket.text: 0,
    };
    for (final post in posts.take(targetCount)) {
      final bucket = _resolveStartupSupportBucket(post);
      if (bucket == null) continue;
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }

    final supportTargets = _startupSupportTargetsForTarget(targetCount);
    var deficitScore = 0;
    for (final entry in supportTargets.entries) {
      final missing = entry.value - (counts[entry.key] ?? 0);
      if (missing > 0) {
        deficitScore += missing;
      }
    }
    return deficitScore;
  }

  _AgendaStartupBucket? _resolveStartupSupportBucket(PostsModel post) {
    if (_isFloodFeedCandidate(post)) {
      return _AgendaStartupBucket.flood;
    }
    if (_isImageStartupCandidate(post)) {
      return _AgendaStartupBucket.image;
    }
    if (_isTextStartupCandidate(post)) {
      return _AgendaStartupBucket.text;
    }
    return null;
  }

  Map<_AgendaStartupBucket, int> _startupSupportTargetsForTarget(
      int targetCount) {
    final slotPlan = _startupSlotPlanForTarget(targetCount);
    final supportTargets = <_AgendaStartupBucket, int>{
      _AgendaStartupBucket.flood: 0,
      _AgendaStartupBucket.image: 0,
      _AgendaStartupBucket.text: 0,
    };
    for (final bucket in slotPlan) {
      if (!supportTargets.containsKey(bucket)) {
        continue;
      }
      supportTargets[bucket] = (supportTargets[bucket] ?? 0) + 1;
    }
    return supportTargets;
  }

  bool _isImageStartupCandidate(PostsModel post) {
    if (post.isFloodSeriesContent || post.hasPlayableVideo) {
      return false;
    }
    return post.hasImageContent;
  }

  bool _isTextStartupCandidate(PostsModel post) {
    if (post.isFloodSeriesContent || post.hasPlayableVideo) {
      return false;
    }
    return post.hasTextContent;
  }

  bool _isImageFeedPresentationCandidate(PostsModel post) {
    if (post.isFloodSeriesContent || post.hasPlayableVideo) {
      return false;
    }
    return post.hasImageContent;
  }

  bool _isTextFeedPresentationCandidate(PostsModel post) {
    if (post.isFloodSeriesContent || post.hasPlayableVideo) {
      return false;
    }
    return post.hasTextContent;
  }

  bool _isFloodFeedCandidate(PostsModel post) {
    return post.isFloodSeriesRoot && post.floodCount.toInt() > 1;
  }

  List<_AgendaStartupBucket> _startupSlotPlanForTarget(int targetCount) {
    if (targetCount <= 0) return const <_AgendaStartupBucket>[];
    final slotPlan = <_AgendaStartupBucket>[];
    while (slotPlan.length < targetCount) {
      final remaining = targetCount - slotPlan.length;
      slotPlan.addAll(
        _startupPreferredPostSlotPlan.take(
          remaining < _startupPreferredPostSlotPlan.length
              ? remaining
              : _startupPreferredPostSlotPlan.length,
        ),
      );
    }
    return slotPlan;
  }

  _AgendaFeedPenaltySnapshot _capturePenaltySnapshot() {
    final service = FeedDiversityMemoryService.maybeFind();
    if (service == null || !service.isReady) {
      return const _AgendaFeedPenaltySnapshot.empty();
    }
    return _AgendaFeedPenaltySnapshot(
      startupHeadDocIds: service.startupHeadPenaltyDocIds(),
      startupHeadFloodRootIds: service.startupHeadPenaltyFloodRootIds(),
      weeklyWatchedDocIds: service.weeklyWatchedPenaltyDocIds(),
      weeklyWatchedFloodRootIds: service.weeklyWatchedFloodRootIds(),
    );
  }

  List<PostsModel> _applyStartupPenaltyOrder(
    List<PostsModel> items, {
    required _AgendaFeedPenaltySnapshot penaltySnapshot,
  }) {
    if (items.length < 2 || !penaltySnapshot.hasStartupPenalties) {
      return items;
    }
    final indexed = items.asMap().entries.toList(growable: false)
      ..sort((left, right) {
        final leftPenalty = _startupPenaltyScore(
          left.value,
          penaltySnapshot: penaltySnapshot,
        );
        final rightPenalty = _startupPenaltyScore(
          right.value,
          penaltySnapshot: penaltySnapshot,
        );
        if (leftPenalty != rightPenalty) {
          return leftPenalty.compareTo(rightPenalty);
        }
        return left.key.compareTo(right.key);
      });
    return indexed.map((entry) => entry.value).toList(growable: false);
  }

  List<PostsModel> _applyPresentationPenaltyOrder(
    List<PostsModel> items, {
    required _AgendaFeedPenaltySnapshot penaltySnapshot,
  }) {
    if (items.length < 2 || !penaltySnapshot.hasPresentationPenalties) {
      return items;
    }
    final indexed = items.asMap().entries.toList(growable: false)
      ..sort((left, right) {
        final leftPenalty = _presentationPenaltyScore(
          left.value,
          penaltySnapshot: penaltySnapshot,
        );
        final rightPenalty = _presentationPenaltyScore(
          right.value,
          penaltySnapshot: penaltySnapshot,
        );
        if (leftPenalty != rightPenalty) {
          return leftPenalty.compareTo(rightPenalty);
        }
        return left.key.compareTo(right.key);
      });
    return indexed.map((entry) => entry.value).toList(growable: false);
  }

  int _startupPenaltyScore(
    PostsModel post, {
    required _AgendaFeedPenaltySnapshot penaltySnapshot,
  }) {
    final docId = post.docID.trim();
    if (docId.isEmpty) return 0;
    final floodRootId = _resolveFloodRootId(post);
    var penalty = 0;
    if (penaltySnapshot.weeklyWatchedDocIds.contains(docId)) {
      penalty += 6;
    }
    if (floodRootId.isNotEmpty &&
        penaltySnapshot.weeklyWatchedFloodRootIds.contains(floodRootId)) {
      penalty += 4;
    }
    if (penaltySnapshot.startupHeadDocIds.contains(docId)) {
      penalty += 3;
    }
    if (floodRootId.isNotEmpty &&
        penaltySnapshot.startupHeadFloodRootIds.contains(floodRootId)) {
      penalty += 2;
    }
    return penalty;
  }

  int _presentationPenaltyScore(
    PostsModel post, {
    required _AgendaFeedPenaltySnapshot penaltySnapshot,
  }) {
    final docId = post.docID.trim();
    if (docId.isEmpty) return 0;
    final floodRootId = _resolveFloodRootId(post);
    var penalty = 0;
    if (penaltySnapshot.weeklyWatchedDocIds.contains(docId)) {
      penalty += 5;
    }
    if (floodRootId.isNotEmpty &&
        penaltySnapshot.weeklyWatchedFloodRootIds.contains(floodRootId)) {
      penalty += 3;
    }
    return penalty;
  }

  String _resolveFloodRootId(PostsModel post) {
    if (!post.isFloodSeriesContent) return '';
    final mainFlood = post.mainFlood.trim();
    if (mainFlood.isNotEmpty) {
      return mainFlood;
    }
    if (post.isFloodSeriesRoot) {
      return post.docID.trim();
    }
    return post.docID.trim().replaceFirst(RegExp(r'_\d+$'), '');
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
