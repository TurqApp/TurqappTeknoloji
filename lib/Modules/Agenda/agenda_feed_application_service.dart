import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Models/posts_model.dart';

enum _AgendaStartupBucket {
  cacheVideo,
  liveVideo,
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

class AgendaFeedApplicationService {
  static const List<_AgendaStartupBucket> _startupPreferredTenSlotPlan =
      <_AgendaStartupBucket>[
    _AgendaStartupBucket.cacheVideo,
    _AgendaStartupBucket.cacheVideo,
    _AgendaStartupBucket.image,
    _AgendaStartupBucket.liveVideo,
    _AgendaStartupBucket.liveVideo,
    _AgendaStartupBucket.flood,
    _AgendaStartupBucket.cacheVideo,
    _AgendaStartupBucket.cacheVideo,
    _AgendaStartupBucket.text,
    _AgendaStartupBucket.liveVideo,
  ];

  AgendaFeedPageApplyPlan buildPageApplyPlan({
    required List<PostsModel> currentItems,
    required List<PostsModel> pageItems,
    required int nowMs,
    required int loadLimit,
    required DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    required bool usesPrimaryFeed,
  }) {
    final existingIds = currentItems.map((post) => post.docID).toSet();
    final itemsToAdd = <PostsModel>[];
    final freshScheduledIds = <String>[];
    final tenMinAgo = nowMs - const Duration(minutes: 15).inMilliseconds;

    for (final post in pageItems) {
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
  }) {
    if (targetCount <= 0) return const <PostsModel>[];

    final split = _splitStartupCandidates(
      liveCandidates: liveCandidates,
      cacheCandidates: cacheCandidates,
      cacheReadyVideoDocIds: cacheReadyVideoDocIds,
    );
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
      _AgendaStartupBucket.flood: normalizedSupport
          .where((post) => post.isFloodSeriesContent)
          .toList(growable: true),
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
        );
        entry.value
          ..clear()
          ..addAll(prepared);
      }
    }

    final output = <PostsModel>[];
    final usedIds = <String>{};
    for (var start = 0; start < slotPlan.length; start += 10) {
      final end = (start + 10 < slotPlan.length) ? start + 10 : slotPlan.length;
      output.addAll(
        _composeStartupSlotChunk(
          slotPlan: slotPlan.sublist(start, end),
          buckets: buckets,
          usedIds: usedIds,
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
  }) {
    if (items.length < 2) {
      return items;
    }
    final ranked = items.toList(growable: true)
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
          _AgendaStartupBucket.liveVideo,
          _AgendaStartupBucket.cacheVideo,
        ];
      case _AgendaStartupBucket.flood:
        return <_AgendaStartupBucket>[
          _AgendaStartupBucket.flood,
          _AgendaStartupBucket.liveVideo,
          _AgendaStartupBucket.cacheVideo,
        ];
      case _AgendaStartupBucket.text:
        return <_AgendaStartupBucket>[
          _AgendaStartupBucket.text,
          _AgendaStartupBucket.liveVideo,
          _AgendaStartupBucket.cacheVideo,
        ];
    }
  }

  List<PostsModel> _composeStartupSlotChunk({
    required List<_AgendaStartupBucket> slotPlan,
    required Map<_AgendaStartupBucket, List<PostsModel>> buckets,
    required Set<String> usedIds,
  }) {
    if (slotPlan.isEmpty) return const <PostsModel>[];

    final output = <PostsModel>[];
    var usedFloodInChunk = false;
    for (final desiredBucket in slotPlan) {
      final candidate = _selectStartupCandidateForSlot(
        desiredBucket: desiredBucket,
        buckets: buckets,
        usedIds: usedIds,
        allowFlood:
            !usedFloodInChunk || desiredBucket == _AgendaStartupBucket.flood,
      );
      if (candidate == null) {
        break;
      }
      final docId = candidate.docID.trim();
      if (docId.isEmpty || !usedIds.add(docId)) {
        break;
      }
      if (candidate.isFloodSeriesContent) {
        usedFloodInChunk = true;
      }
      output.add(candidate);
    }
    return output;
  }

  PostsModel? _selectStartupCandidateForSlot({
    required _AgendaStartupBucket desiredBucket,
    required Map<_AgendaStartupBucket, List<PostsModel>> buckets,
    required Set<String> usedIds,
    required bool allowFlood,
  }) {
    for (final bucket in _startupSlotFallbackOrder(desiredBucket)) {
      if (bucket == _AgendaStartupBucket.flood && !allowFlood) {
        continue;
      }
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
    if (targetCount < _startupPreferredTenSlotPlan.length) {
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
    if (post.isFloodSeriesContent) {
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

  List<_AgendaStartupBucket> _startupSlotPlanForTarget(int targetCount) {
    if (targetCount <= 0) return const <_AgendaStartupBucket>[];
    final slotPlan = <_AgendaStartupBucket>[];
    while (slotPlan.length < targetCount) {
      final remaining = targetCount - slotPlan.length;
      slotPlan.addAll(
        _startupPreferredTenSlotPlan.take(
          remaining < _startupPreferredTenSlotPlan.length
              ? remaining
              : _startupPreferredTenSlotPlan.length,
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
