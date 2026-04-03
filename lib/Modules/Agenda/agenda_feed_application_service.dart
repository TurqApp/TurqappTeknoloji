import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Services/startup_surface_order_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

enum _AgendaStartupBucket {
  cacheVideo,
  liveVideo,
  image,
  flood,
  text,
}

enum _AgendaStartupSlotKind {
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

class AgendaFeedApplicationService {
  static const List<_AgendaStartupBucket> _startupGlobalFallbackOrder =
      <_AgendaStartupBucket>[
    _AgendaStartupBucket.liveVideo,
    _AgendaStartupBucket.cacheVideo,
    _AgendaStartupBucket.image,
    _AgendaStartupBucket.text,
    _AgendaStartupBucket.flood,
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
    final startupVariant = startupVariantOverride ??
        startupVariantIndexForSurface(
          surfaceKey: 'feed_visible_startup_head',
          sessionNamespace: 'feed',
          variantCount: 10,
        );
    final normalizedLive = reorderForStartupSurface(
      _dedupePosts(split.liveCandidates),
      surfaceKey: 'feed_startup_live_pool_v$startupVariant',
      sessionNamespace: 'feed',
      maxShuffleWindow: split.liveCandidates.length,
    );
    final normalizedCache = _dedupePosts(split.cacheCandidates);
    final orderedCache = reorderForStartupSurface(
      normalizedCache,
      surfaceKey: 'feed_startup_cache_pool_v$startupVariant',
      sessionNamespace: 'feed',
      maxShuffleWindow: normalizedCache.length,
    );
    final buckets = <_AgendaStartupBucket, List<PostsModel>>{
      _AgendaStartupBucket.cacheVideo: <PostsModel>[],
      _AgendaStartupBucket.liveVideo: <PostsModel>[],
      _AgendaStartupBucket.image: <PostsModel>[],
      _AgendaStartupBucket.flood: <PostsModel>[],
      _AgendaStartupBucket.text: <PostsModel>[],
    };
    final seenIds = <String>{};
    for (final post in normalizedLive) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenIds.add(docId)) continue;
      final bucket = _resolveStartupBucket(post, isLiveCandidate: true);
      if (bucket == null) continue;
      buckets[bucket]!.add(post);
    }
    for (final post in orderedCache) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenIds.add(docId)) continue;
      final bucket = _resolveStartupBucket(post, isLiveCandidate: false);
      if (bucket == null) continue;
      buckets[bucket]!.add(post);
    }

    final orderedBuckets = <_AgendaStartupBucket, List<PostsModel>>{
      for (final entry in buckets.entries)
        entry.key: reorderForStartupSurface(
          entry.value,
          surfaceKey:
              'feed_startup_${_startupBucketKey(entry.key)}_v$startupVariant',
          sessionNamespace: 'feed',
          maxShuffleWindow: entry.value.length,
        ),
    };

    final slotPlan = _buildStartupSlotPlan(
      buckets: orderedBuckets,
      targetCount: targetCount,
      startupVariant: startupVariant,
    );
    final cursorByBucket = <_AgendaStartupBucket, int>{
      _AgendaStartupBucket.cacheVideo: 0,
      _AgendaStartupBucket.liveVideo: 0,
      _AgendaStartupBucket.image: 0,
      _AgendaStartupBucket.flood: 0,
      _AgendaStartupBucket.text: 0,
    };

    final output = <PostsModel>[];
    var videoSelectionCount = 0;
    for (final desiredSlot in slotPlan) {
      final selectedBucket = _selectStartupBucketForSlot(
        desiredSlot,
        orderedBuckets,
        cursorByBucket,
        videoSelectionCount: videoSelectionCount,
        startupVariant: startupVariant,
      );
      if (selectedBucket == null) continue;
      final cursor = cursorByBucket[selectedBucket] ?? 0;
      output.add(orderedBuckets[selectedBucket]![cursor]);
      cursorByBucket[selectedBucket] = cursor + 1;
      if (_isVideoBucket(selectedBucket)) {
        videoSelectionCount += 1;
      }
      if (output.length >= targetCount) break;
    }

    while (output.length < targetCount) {
      final selectedBucket = _selectFallbackStartupBucket(
        orderedBuckets,
        cursorByBucket,
        videoSelectionCount: videoSelectionCount,
        startupVariant: startupVariant,
      );
      if (selectedBucket == null) break;
      final cursor = cursorByBucket[selectedBucket] ?? 0;
      output.add(orderedBuckets[selectedBucket]![cursor]);
      cursorByBucket[selectedBucket] = cursor + 1;
      if (_isVideoBucket(selectedBucket)) {
        videoSelectionCount += 1;
      }
    }

    return output.take(targetCount).toList(growable: false);
  }

  List<PostsModel> mergeStartupHeadWithCurrentItems({
    required List<PostsModel> currentItems,
    required List<PostsModel> liveItems,
    required int targetCount,
    required int nowMs,
    int? startupVariantOverride,
    Set<String>? cacheReadyVideoDocIds,
  }) {
    final refreshPlan = buildRefreshPlan(
      currentItems: currentItems,
      fetchedPosts: liveItems,
      nowMs: nowMs,
    );
    final fetchedById = <String, PostsModel>{
      for (final post in liveItems) post.docID: post,
    };
    final updatedCurrentItems = currentItems
        .map((post) => fetchedById[post.docID] ?? post)
        .toList(growable: false);
    final startupHead = composeStartupFeedItems(
      liveCandidates: liveItems,
      cacheCandidates: updatedCurrentItems,
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

  _AgendaStartupBucket? _resolveStartupBucket(
    PostsModel post, {
    required bool isLiveCandidate,
  }) {
    if (post.isFloodSeriesRoot) {
      return _AgendaStartupBucket.flood;
    }
    if (post.hasPlayableVideo) {
      return isLiveCandidate
          ? _AgendaStartupBucket.liveVideo
          : _AgendaStartupBucket.cacheVideo;
    }
    if (!post.hasVideoSignal && post.hasImageContent) {
      return _AgendaStartupBucket.image;
    }
    if (!post.hasVideoSignal && !post.hasImageContent && post.hasTextContent) {
      return _AgendaStartupBucket.text;
    }
    return null;
  }

  _AgendaStartupBucket? _selectStartupBucketForSlot(
      _AgendaStartupSlotKind desiredSlot,
      Map<_AgendaStartupBucket, List<PostsModel>> buckets,
      Map<_AgendaStartupBucket, int> cursorByBucket,
      {required int videoSelectionCount,
      required int startupVariant}) {
    for (final bucket in _startupSlotFallbackOrder(
      desiredSlot,
      videoSelectionCount: videoSelectionCount,
      startupVariant: startupVariant,
    )) {
      final cursor = cursorByBucket[bucket] ?? 0;
      final items = buckets[bucket]!;
      if (cursor < items.length) {
        return bucket;
      }
    }
    return null;
  }

  _AgendaStartupBucket? _selectFallbackStartupBucket(
      Map<_AgendaStartupBucket, List<PostsModel>> buckets,
      Map<_AgendaStartupBucket, int> cursorByBucket,
      {required int videoSelectionCount,
      required int startupVariant}) {
    final preferredVideoOrder = _preferredVideoBucketOrder(
      videoSelectionCount,
      startupVariant,
    );
    final fallbackOrder = <_AgendaStartupBucket>[
      ...preferredVideoOrder,
      ..._startupGlobalFallbackOrder.where(
        (bucket) => !preferredVideoOrder.contains(bucket),
      ),
    ];
    for (final bucket in fallbackOrder) {
      final cursor = cursorByBucket[bucket] ?? 0;
      final items = buckets[bucket]!;
      if (cursor < items.length) {
        return bucket;
      }
    }
    return null;
  }

  List<_AgendaStartupBucket> _startupSlotFallbackOrder(
    _AgendaStartupSlotKind desiredSlot, {
    required int videoSelectionCount,
    required int startupVariant,
  }) {
    final preferredVideoOrder = _preferredVideoBucketOrder(
      videoSelectionCount,
      startupVariant,
    );
    switch (desiredSlot) {
      case _AgendaStartupSlotKind.video:
        return <_AgendaStartupBucket>[
          ...preferredVideoOrder,
          _AgendaStartupBucket.image,
          _AgendaStartupBucket.text,
          _AgendaStartupBucket.flood,
        ];
      case _AgendaStartupSlotKind.image:
        return <_AgendaStartupBucket>[
          _AgendaStartupBucket.image,
          ...preferredVideoOrder,
          _AgendaStartupBucket.text,
          _AgendaStartupBucket.flood,
        ];
      case _AgendaStartupSlotKind.flood:
        return <_AgendaStartupBucket>[
          _AgendaStartupBucket.flood,
          ...preferredVideoOrder,
          _AgendaStartupBucket.image,
          _AgendaStartupBucket.text,
        ];
      case _AgendaStartupSlotKind.text:
        return <_AgendaStartupBucket>[
          _AgendaStartupBucket.text,
          ...preferredVideoOrder,
          _AgendaStartupBucket.image,
          _AgendaStartupBucket.flood,
        ];
    }
  }

  List<_AgendaStartupSlotKind> _buildStartupSlotPlan({
    required Map<_AgendaStartupBucket, List<PostsModel>> buckets,
    required int targetCount,
    required int startupVariant,
  }) {
    if (targetCount <= 0) return const <_AgendaStartupSlotKind>[];

    final supportKinds = <_AgendaStartupSlotKind>[
      if (buckets[_AgendaStartupBucket.image]!.isNotEmpty)
        _AgendaStartupSlotKind.image,
      if (buckets[_AgendaStartupBucket.text]!.isNotEmpty)
        _AgendaStartupSlotKind.text,
    ];
    final hasFlood = buckets[_AgendaStartupBucket.flood]!.isNotEmpty;
    final slotPlan = <_AgendaStartupSlotKind>[];
    var supportIndex =
        supportKinds.isEmpty ? 0 : startupVariant % supportKinds.length;

    while (slotPlan.length < targetCount) {
      slotPlan.addAll(const <_AgendaStartupSlotKind>[
        _AgendaStartupSlotKind.video,
        _AgendaStartupSlotKind.video,
        _AgendaStartupSlotKind.video,
      ]);
      if (slotPlan.length >= targetCount) break;

      final primarySupport = _nextSupportSlot(
        supportKinds,
        supportIndex,
      );
      if (primarySupport != null) {
        slotPlan.add(primarySupport);
        supportIndex += 1;
      } else {
        slotPlan.add(_AgendaStartupSlotKind.video);
      }
      if (slotPlan.length >= targetCount) break;

      if (hasFlood) {
        slotPlan.add(_AgendaStartupSlotKind.flood);
      } else {
        final secondarySupport = _nextSupportSlot(
          supportKinds,
          supportIndex,
        );
        if (secondarySupport != null) {
          slotPlan.add(secondarySupport);
          supportIndex += 1;
        } else {
          slotPlan.add(_AgendaStartupSlotKind.video);
        }
      }
    }

    return slotPlan.take(targetCount).toList(growable: false);
  }

  _AgendaStartupSlotKind? _nextSupportSlot(
    List<_AgendaStartupSlotKind> supportKinds,
    int supportIndex,
  ) {
    if (supportKinds.isEmpty) return null;
    return supportKinds[supportIndex % supportKinds.length];
  }

  List<_AgendaStartupBucket> _preferredVideoBucketOrder(
    int videoSelectionCount,
    int startupVariant,
  ) {
    if ((videoSelectionCount + startupVariant).isEven) {
      return const <_AgendaStartupBucket>[
        _AgendaStartupBucket.cacheVideo,
        _AgendaStartupBucket.liveVideo,
      ];
    }
    return const <_AgendaStartupBucket>[
      _AgendaStartupBucket.liveVideo,
      _AgendaStartupBucket.cacheVideo,
    ];
  }

  String _startupBucketKey(_AgendaStartupBucket bucket) {
    switch (bucket) {
      case _AgendaStartupBucket.cacheVideo:
        return 'cache_video';
      case _AgendaStartupBucket.liveVideo:
        return 'live_video';
      case _AgendaStartupBucket.image:
        return 'image';
      case _AgendaStartupBucket.flood:
        return 'flood';
      case _AgendaStartupBucket.text:
        return 'text';
    }
  }

  bool _isVideoBucket(_AgendaStartupBucket bucket) =>
      bucket == _AgendaStartupBucket.cacheVideo ||
      bucket == _AgendaStartupBucket.liveVideo;

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
}

class _AgendaStartupCandidateSplit {
  const _AgendaStartupCandidateSplit({
    required this.cacheCandidates,
    required this.liveCandidates,
  });

  final List<PostsModel> cacheCandidates;
  final List<PostsModel> liveCandidates;
}
