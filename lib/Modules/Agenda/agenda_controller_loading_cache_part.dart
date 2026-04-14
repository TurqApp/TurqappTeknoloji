part of 'agenda_controller.dart';

extension AgendaControllerLoadingCachePart on AgendaController {
  int _startupSeedLoadLimit(int targetCount) {
    if (targetCount <= 0) return 0;
    return max(targetCount * 5, 100);
  }

  int _startupShardCandidateLimit(int targetCount) {
    if (targetCount <= 0) return 0;
    return min(_startupSeedLoadLimit(targetCount), 100);
  }

  List<PostsModel> _buildOrderedAgendaSnapshot({required int limit}) {
    final ordered = agendaList.toList(growable: false)
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return ordered.take(limit).toList(growable: false);
  }

  Set<String> _startupCacheReadyVideoDocIds(Iterable<PostsModel> posts) {
    final cacheManager = maybeFindSegmentCacheManager();
    if (cacheManager == null) return const <String>{};
    final readyDocIds = <String>{};
    for (final post in posts) {
      if (!post.hasPlayableVideo) continue;
      final docId = post.docID.trim();
      if (docId.isEmpty) continue;
      final isFullyCached =
          cacheManager.getEntry(docId)?.isFullyCached ?? false;
      if (isFullyCached) {
        readyDocIds.add(docId);
      }
    }
    return readyDocIds;
  }

  Set<String> _startupCacheOriginVideoDocIdsForShownItems({
    required Iterable<PostsModel> shownItems,
    required Iterable<PostsModel> cacheCandidates,
    Iterable<PostsModel> liveCandidates = const <PostsModel>[],
  }) {
    final liveDocIds = <String>{
      for (final post in liveCandidates)
        if (post.docID.trim().isNotEmpty) post.docID.trim(),
    };
    final cacheDocIds = <String>{
      for (final post in cacheCandidates)
        if (post.hasPlayableVideo &&
            post.docID.trim().isNotEmpty &&
            !liveDocIds.contains(post.docID.trim()))
          post.docID.trim(),
    };
    return <String>{
      for (final post in shownItems)
        if (post.hasPlayableVideo && cacheDocIds.contains(post.docID.trim()))
          post.docID.trim(),
    };
  }

  int _feedStartupVariantOverride() => startupVariantIndexForSurface(
        surfaceKey: 'feed_startup_head',
        sessionNamespace: 'feed',
        variantCount: 997,
      );

  List<PostsModel> _buildStartupPlannerHead({
    required List<PostsModel> cacheCandidates,
    List<PostsModel> liveCandidates = const <PostsModel>[],
    required int targetCount,
    bool allowSparseSlotFallback = false,
  }) {
    if ((cacheCandidates.isEmpty && liveCandidates.isEmpty) ||
        targetCount <= 0) {
      _startupPlannerHeadApplied = false;
      _startupCacheOriginVideoDocIds.clear();
      return const <PostsModel>[];
    }
    final startupVariant = _feedStartupVariantOverride();
    final cacheReadyVideoDocIds = _startupCacheReadyVideoDocIds(<PostsModel>[
      ...cacheCandidates,
      ...liveCandidates,
    ]);
    final shownItems = _agendaFeedApplicationService.buildStartupPlannerHead(
      liveCandidates: liveCandidates,
      cacheCandidates: cacheCandidates,
      targetCount: targetCount,
      startupVariantOverride: startupVariant,
      cacheReadyVideoDocIds: cacheReadyVideoDocIds,
      allowSparseSlotFallback: allowSparseSlotFallback,
    );
    _startupCacheOriginVideoDocIds
      ..clear()
      ..addAll(
        _startupCacheOriginVideoDocIdsForShownItems(
          shownItems: shownItems,
          cacheCandidates: cacheCandidates,
          liveCandidates: liveCandidates,
        ),
      );
    _startupPlannerHeadApplied = shownItems.isNotEmpty;
    assert(() {
      final cacheDocIds = <String>{
        for (final post in cacheCandidates)
          if (post.docID.trim().isNotEmpty) post.docID.trim(),
      };
      final liveDocIds = <String>{
        for (final post in liveCandidates)
          if (post.docID.trim().isNotEmpty) post.docID.trim(),
      };
      final slots = shownItems.asMap().entries.map((entry) {
        final post = entry.value;
        final docId = post.docID.trim();
        final kind = _startupDebugKindForPost(
          post,
          cacheDocIds: cacheDocIds,
          liveDocIds: liveDocIds,
        );
        return '${entry.key + 1}:$kind:$docId';
      }).join(' | ');
      debugPrint('[FeedStartupOrder] count=${shownItems.length} slots=$slots');
      return true;
    }());
    if (shownItems.isNotEmpty) {
      FeedDiversityMemoryService.ensure().rememberStartupHead(shownItems);
    }
    return shownItems;
  }

  String _startupDebugKindForPost(
    PostsModel post, {
    required Set<String> cacheDocIds,
    required Set<String> liveDocIds,
  }) {
    final docId = post.docID.trim();
    final origin = cacheDocIds.contains(docId)
        ? 'cache'
        : (liveDocIds.contains(docId) ? 'live' : 'mixed');
    if (post.isFloodSeriesContent) return 'flood@$origin';
    final text = post.metin.trim().isNotEmpty;
    final hasMedia = post.img.any((entry) => entry.trim().isNotEmpty) ||
        post.video.trim().isNotEmpty ||
        post.thumbnail.trim().isNotEmpty;
    if (text && !hasMedia) return 'text@$origin';
    if (post.hasPlayableVideo) {
      return origin == 'live' ? 'live' : 'cache';
    }
    return 'image@$origin';
  }

  Map<String, int> _startupSupportSlotTargetsForCount(int targetCount) {
    if (targetCount <= 0) return const <String, int>{};
    final targets = <String, int>{'flood': 0, 'image': 0, 'text': 0};
    for (var index = 0; index < targetCount; index++) {
      final bucket = FeedRenderBlockPlan
          .postSlotPlan[index % FeedRenderBlockPlan.postSlotPlan.length];
      switch (bucket) {
        case FeedPlannerPostBucket.flood:
          targets['flood'] = (targets['flood'] ?? 0) + 1;
          break;
        case FeedPlannerPostBucket.image:
          targets['image'] = (targets['image'] ?? 0) + 1;
          break;
        case FeedPlannerPostBucket.text:
          targets['text'] = (targets['text'] ?? 0) + 1;
          break;
        case FeedPlannerPostBucket.cache:
        case FeedPlannerPostBucket.live:
          break;
      }
    }
    return targets;
  }

  int _startupSupportFallbackCutoffMs(int nowMs) =>
      nowMs - const Duration(days: 7).inMilliseconds;

  int _startupFloodSupportFetchLimit(int targetCount) {
    final normalizedTarget = targetCount < 1 ? 1 : targetCount;
    return max(normalizedTarget * 3, 120);
  }

  String? _startupSupportKind(PostsModel post) {
    if (post.isFloodSeriesContent) return 'flood';
    if (post.hasPlayableVideo) return null;
    final hasText = post.metin.trim().isNotEmpty;
    final hasImage = post.img.any((entry) => entry.trim().isNotEmpty) ||
        post.thumbnail.trim().isNotEmpty;
    if (hasText && !hasImage) return 'text';
    if (hasImage) return 'image';
    return null;
  }

  Map<String, int> _startupSupportDeficits(
    List<PostsModel> posts, {
    required int targetCount,
  }) {
    if (targetCount < FeedRenderBlockPlan.postSlotsPerBlock) {
      return const <String, int>{};
    }
    final supportTargets = _startupSupportSlotTargetsForCount(targetCount);
    final counts = <String, int>{'flood': 0, 'image': 0, 'text': 0};
    for (final post in posts) {
      final kind = _startupSupportKind(post);
      if (kind == null) continue;
      counts[kind] = (counts[kind] ?? 0) + 1;
    }
    final deficits = <String, int>{};
    for (final entry in supportTargets.entries) {
      final current = counts[entry.key] ?? 0;
      final missing = entry.value - current;
      if (missing > 0) {
        deficits[entry.key] = missing;
      }
    }
    return deficits;
  }

  Map<String, int> _startupSupportCounts(
    Iterable<PostsModel> posts,
  ) {
    final counts = <String, int>{'flood': 0, 'image': 0, 'text': 0};
    for (final post in posts) {
      final kind = _startupSupportKind(post);
      if (kind == null) continue;
      counts[kind] = (counts[kind] ?? 0) + 1;
    }
    return counts;
  }

  Future<List<PostsModel>> _augmentStartupSupportCandidates({
    required List<PostsModel> candidates,
    required int nowMs,
    required int primaryCutoffMs,
    required int targetCount,
    required bool preferCache,
    required bool cacheOnly,
    bool allowNetworkFallbackFetch = true,
    Set<String> excludeDocIds = const <String>{},
    DocumentSnapshot<Map<String, dynamic>>? fallbackStartAfter,
  }) async {
    final supportFallbackCutoffMs = _startupSupportFallbackCutoffMs(nowMs);
    final seenDocIds = <String>{
      for (final docId in excludeDocIds)
        if (docId.trim().isNotEmpty) docId.trim(),
    };
    final primaryCandidates = <PostsModel>[];
    final fallbackPool = <PostsModel>[];

    for (final post in candidates) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenDocIds.add(docId)) continue;
      final ts = post.timeStamp.toInt();
      final kind = _startupSupportKind(post);
      if (kind == 'flood') {
        primaryCandidates.add(post);
        continue;
      }
      if (ts >= primaryCutoffMs) {
        primaryCandidates.add(post);
        continue;
      }
      if (ts < supportFallbackCutoffMs) {
        continue;
      }
      if (kind == null) {
        continue;
      }
      fallbackPool.add(post);
    }

    if (primaryCandidates.length != candidates.length) {
      debugPrint(
        '[FeedStartupWindow] primary=${primaryCandidates.length} '
        'fallbackPool=${fallbackPool.length} '
        'dropped=${candidates.length - primaryCandidates.length - fallbackPool.length}',
      );
    }

    final deficits = _startupSupportDeficits(
      primaryCandidates,
      targetCount: targetCount,
    );
    debugPrint(
      '[FeedStartupSupport] primaryCounts=${_startupSupportCounts(primaryCandidates)} '
      'fallbackPoolCounts=${_startupSupportCounts(fallbackPool)} '
      'deficits=$deficits targetCount=$targetCount',
    );
    if (deficits.isEmpty) {
      return primaryCandidates;
    }

    final fallbackLimit =
        max(FeedSnapshotRepository.startupHomeLimitValue * 4, 120);
    final remaining = Map<String, int>.from(deficits);
    final additions = <PostsModel>[];

    for (final post in fallbackPool) {
      final kind = _startupSupportKind(post);
      if (kind == null) continue;
      final missing = remaining[kind] ?? 0;
      if (missing <= 0) continue;
      additions.add(post);
      remaining[kind] = missing - 1;
      if (remaining.values.every((value) => value <= 0)) {
        break;
      }
    }

    if (remaining.values.every((value) => value <= 0)) {
      return <PostsModel>[
        ...primaryCandidates,
        ...additions,
      ];
    }

    if (!allowNetworkFallbackFetch) {
      return <PostsModel>[
        ...primaryCandidates,
        ...additions,
      ];
    }

    final missingFloodCount = remaining['flood'] ?? 0;
    if (missingFloodCount > 0) {
      final floodRoots = await _postRepository.fetchFloodSeriesRoots(
        limit: _startupFloodSupportFetchLimit(targetCount),
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      for (final post in floodRoots) {
        final docId = post.docID.trim();
        if (docId.isEmpty || !seenDocIds.add(docId)) continue;
        additions.add(post);
        remaining['flood'] = (remaining['flood'] ?? 0) - 1;
        if ((remaining['flood'] ?? 0) <= 0) {
          break;
        }
      }
      if (remaining.values.every((value) => value <= 0)) {
        return <PostsModel>[
          ...primaryCandidates,
          ...additions,
        ];
      }
    }

    final page = await _loadAgendaSourcePage(
      nowMs: nowMs,
      cutoffMs: supportFallbackCutoffMs,
      limit: fallbackLimit,
      startAfter: fallbackStartAfter,
      useStoredCursor: false,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    if (page.items.isEmpty) {
      debugPrint(
        '[FeedStartupSupport] fallbackPageCounts={} remaining=$remaining',
      );
      return <PostsModel>[
        ...primaryCandidates,
        ...additions,
      ];
    }

    debugPrint(
      '[FeedStartupSupport] fallbackPageCounts=${_startupSupportCounts(page.items)} '
      'remainingBeforeScan=$remaining',
    );

    for (final post in page.items) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenDocIds.add(docId)) continue;
      final ts = post.timeStamp.toInt();
      if (ts < supportFallbackCutoffMs) continue;
      final kind = _startupSupportKind(post);
      if (kind == null) continue;
      final missing = remaining[kind] ?? 0;
      if (missing <= 0) continue;
      additions.add(post);
      remaining[kind] = missing - 1;
      if (remaining.values.every((value) => value <= 0)) {
        break;
      }
    }

    if (additions.isNotEmpty) {
      debugPrint(
        '[FeedStartupSupportFallback] primary=${primaryCandidates.length} '
        'added=${additions.length} deficits=$deficits '
        'remaining=$remaining sample=${additions.take(5).map((post) => post.docID).join(',')}',
      );
    }
    return <PostsModel>[...primaryCandidates, ...additions];
  }

  List<PostsModel> _applyStartupPlannerHeadOrder(
    List<PostsModel> posts,
    {
    bool allowSparseSlotFallback = false,
  }
  ) {
    if (_startupPlannerHeadApplied || posts.length < 2) {
      return posts;
    }
    return _buildStartupPlannerHead(
      cacheCandidates: const <PostsModel>[],
      liveCandidates: posts,
      targetCount: min(
        posts.length,
        FeedSnapshotRepository.startupHomeLimitValue,
      ),
      allowSparseSlotFallback: allowSparseSlotFallback,
    );
  }

  // ignore: unused_element
  Future<void> _postPoolFillCleanup(
      List<PostsModel> originalPool, List<PostsModel> shown) async {
    try {
      final valid = await _validatePoolPostsAndPrune(originalPool);
      final validIds = valid.map((p) => p.docID).toSet();

      final uniqueUserIDs = valid.map((e) => e.userID).toSet().toList();
      final userPrivacy = <String, bool>{};
      final userDeactivated = <String, bool>{};
      final userMeta = <String, Map<String, dynamic>>{};
      final unresolved = _primeAgendaUserStateFromCaches(
        uniqueUserIDs,
        userPrivacy,
        userDeactivated,
        userMeta,
      );
      if (unresolved.isNotEmpty) {
        await _fillAgendaUserStateFromProfiles(
          unresolved,
          userPrivacy,
          userDeactivated,
          userMeta,
          includeMeta: true,
        );
      }

      final toRemove = <String>[];
      for (final post in shown) {
        if (!validIds.contains(post.docID)) {
          toRemove.add(post.docID);
          continue;
        }
        if (userDeactivated[post.userID] == true) {
          toRemove.add(post.docID);
          continue;
        }
        final meta = userMeta[post.userID] ?? const <String, dynamic>{};
        final rozet =
            (meta['rozet'] ?? meta['badge'] ?? post.rozet).toString().trim();
        final isApproved = meta['isApproved'] == true;
        final canSeeAuthor =
            _visibilityPolicy.canViewerSeeDiscoveryAuthorFromSummary(
          authorUserId: post.userID,
          followingIds: followingIDs,
          rozet: rozet,
          isApproved: isApproved,
          isDeleted: false,
        );
        if (!canSeeAuthor) {
          toRemove.add(post.docID);
        }
      }

      if (toRemove.isNotEmpty) {
        _removeAgendaDocIds(
          toRemove.toSet(),
          reason: 'post_pool_fill_cleanup',
        );
      }

      _scheduleReshareFetchForPosts(agendaList, perPostLimit: 1);
    } catch (_) {}
  }

  Future<List<PostsModel>> _validatePoolPostsAndPrune(
      List<PostsModel> posts) async {
    if (posts.isEmpty) return const <PostsModel>[];

    final postIds =
        posts.map((e) => e.docID).where((e) => e.isNotEmpty).toSet();
    final userIds =
        posts.map((e) => e.userID).where((e) => e.isNotEmpty).toSet();

    final validPostIds = <String>{};
    final preferCache = !ContentPolicy.isConnected;
    final cacheOnly = !ContentPolicy.isConnected;
    for (final chunk in _chunkList(postIds.toList(), 10)) {
      final postsById = await _postRepository.fetchPostCardsByIds(
        chunk,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final entry in postsById.entries) {
        final post = entry.value;
        final deleted = post.deletedPost == true;
        final archived = post.arsiv == true;
        final timeStamp = post.timeStamp.toInt();
        if (!deleted && !archived && _isInAgendaWindow(timeStamp, nowMs)) {
          validPostIds.add(entry.key);
        }
      }
    }

    final validUserIds = <String>{};
    for (final chunk in _chunkList(userIds.toList(), 20)) {
      final users = await _profileCache.getProfiles(
        chunk,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      for (final entry in users.entries) {
        final data = entry.value;
        final deactivated = _isUserMarkedDeactivated(data);
        _userDeactivatedCache[entry.key] = deactivated;
        _userPrivacyCache[entry.key] = (data['isPrivate'] ?? false) == true;
        if (!deactivated) {
          validUserIds.add(entry.key);
        }
      }
    }

    final valid = posts
        .where((p) =>
            validPostIds.contains(p.docID) && validUserIds.contains(p.userID))
        .toList();
    if (valid.length == posts.length) return valid;

    final invalidIds = posts
        .where((p) =>
            !validPostIds.contains(p.docID) || !validUserIds.contains(p.userID))
        .map((p) => p.docID)
        .toList();
    final indexPool = IndexPoolStore.maybeFind();
    if (invalidIds.isNotEmpty && indexPool != null) {
      await indexPool.removePosts(IndexPoolKind.feed, invalidIds);
    }

    return valid;
  }

  Future<_AgendaSourcePage> _loadAgendaSourcePage({
    required int nowMs,
    required int cutoffMs,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    bool useStoredCursor = true,
    bool preferCache = true,
    bool cacheOnly = false,
    bool? usePrimaryFeedPaging,
    bool includeSupplementalSources = true,
  }) async {
    final currentUserService = CurrentUserService.instance;
    final uid = currentUserService.effectiveUserId.trim();
    if (uid.isEmpty || !currentUserService.hasAuthUser) {
      return _loadLegacyAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        startAfter: startAfter,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
    }

    final page = await _feedSnapshotRepository.fetchHomePage(
      userId: uid,
      followingIds: const <String>{},
      hiddenPostIds: hiddenPosts.toSet(),
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      startAfter: startAfter ??
          (useStoredCursor && lastDoc is DocumentSnapshot<Map<String, dynamic>>
              ? lastDoc as DocumentSnapshot<Map<String, dynamic>>
              : null),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
      usePrimaryFeedPaging: usePrimaryFeedPaging ?? _usePrimaryFeedPaging,
      includeSupplementalSources: includeSupplementalSources,
    );
    return _AgendaSourcePage(
      page.items,
      page.lastDoc,
      page.usesPrimaryFeed,
    );
  }

  Future<_AgendaSourcePage> _loadLegacyAgendaSourcePage({
    required int nowMs,
    required int cutoffMs,
    required int limit,
    DocumentSnapshot? startAfter,
    bool useStoredCursor = true,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final page = await _postRepository.fetchAgendaWindowPage(
      cutoffMs: cutoffMs,
      nowMs: nowMs,
      limit: limit,
      startAfter: startAfter ?? (useStoredCursor ? lastDoc : null),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    return _AgendaSourcePage(
      page.items
          .where((p) => _isEligibleAgendaPost(p, nowMs))
          .where((p) => p.deletedPost != true)
          .toList(growable: false),
      page.lastDoc,
      false,
    );
  }

  List<List<T>> _chunkList<T>(List<T> input, int size) {
    if (input.isEmpty) return <List<T>>[];
    final chunks = <List<T>>[];
    for (int i = 0; i < input.length; i += size) {
      final end = (i + size > input.length) ? input.length : i + size;
      chunks.add(input.sublist(i, end));
    }
    return chunks;
  }
}
