part of 'explore_controller.dart';

extension ExploreControllerFeedPart on ExploreController {
  void _performBindShortReadyMirror() {
    final shortController = ensureShortController();
    _shortsMirrorWorker?.dispose();
    _shortsMirrorWorker = ever<List<PostsModel>>(
      shortController.shorts,
      (items) {
        _performAdoptShortReadyPosts(items);
      },
    );
  }

  bool _performHasSameExploreOrder(
    List<PostsModel> current,
    List<PostsModel> next,
  ) {
    if (identical(current, next)) return true;
    if (current.length != next.length) return false;
    for (int i = 0; i < current.length; i++) {
      if (current[i].docID != next[i].docID) {
        return false;
      }
    }
    return true;
  }

  bool _performAdoptShortReadyPosts(List<PostsModel> source) {
    if (source.isEmpty) return false;
    final mirrored = _dedupeExplorePosts(
      source.where(_isEligibleExplorePost).toList(growable: false),
    );
    if (mirrored.isEmpty) return false;
    final prioritized = _prioritizeCachedVideos(mirrored);
    if (!_performHasSameExploreOrder(explorePosts, prioritized)) {
      explorePosts.assignAll(prioritized);
    }
    lastExploreDoc = null;
    exploreHasMore.value = false;
    _exploreEmptyScans = 0;
    return true;
  }

  Future<bool> _performSyncExploreFromShorts({
    bool ensureReady = false,
    bool forceRefresh = false,
    bool nearEnd = false,
  }) async {
    final shortController = ensureShortController();
    if (forceRefresh) {
      await shortController.refreshShorts();
    } else if (ensureReady) {
      await shortController.warmStart(
        targetCount: ReadBudgetRegistry.shortHomeInitialLimit,
        maxPages: 2,
      );
    }
    if (nearEnd && shortController.shorts.isNotEmpty) {
      await shortController.loadMoreIfNeeded(shortController.shorts.length - 1);
    }
    return _performAdoptShortReadyPosts(shortController.shorts);
  }

  void _performSyncScrollToTopVisibility(double offset) {
    final shouldShow = offset > 500;
    if (showScrollToTop.value == shouldShow) {
      return;
    }
    showScrollToTop.value = shouldShow;
  }

  void _performDisposeFloodContentController(String docId) {
    final tag = floodSeriesInstanceTag(docId);
    if (AgendaContentController.maybeFind(tag: tag) != null) {
      Get.delete<AgendaContentController>(tag: tag, force: true);
    }
  }

  void _performUpdateFloodVisibleIndex() {
    if (!floodsScroll.hasClients || exploreFloods.isEmpty) return;
    final position = floodsScroll.position;
    if (position.pixels <= 0) {
      floodsVisibleIndex.value = 0;
      lastFloodVisibleIndex = 0;
      capturePendingFloodEntry(preferredIndex: 0);
      _performScheduleExploreFloodPrefetchFromVisible(preferredIndex: 0);
      _performFetchFloodsIfNearVisibleEnd(preferredIndex: 0);
      return;
    }
    final estimatedItemExtent = (position.viewportDimension * 0.74).clamp(
      320.0,
      680.0,
    );
    final nextIndex = (((position.pixels + position.viewportDimension * 0.25) /
                estimatedItemExtent)
            .floor())
        .clamp(0, exploreFloods.length - 1);
    if (lastFloodVisibleIndex != null &&
        lastFloodVisibleIndex != nextIndex &&
        lastFloodVisibleIndex! >= 0 &&
        lastFloodVisibleIndex! < exploreFloods.length) {
      disposeFloodContentController(
          exploreFloods[lastFloodVisibleIndex!].docID);
    }
    floodsVisibleIndex.value = nextIndex;
    lastFloodVisibleIndex = nextIndex;
    capturePendingFloodEntry(preferredIndex: nextIndex);
    _performScheduleExploreFloodPrefetchFromVisible(preferredIndex: nextIndex);
    _performFetchFloodsIfNearVisibleEnd(preferredIndex: nextIndex);
  }

  int _performResolveFloodSeriesFocusIndex() {
    if (exploreFloods.isEmpty) return -1;
    final pendingDocId = _pendingFloodDocId;
    if (pendingDocId != null && pendingDocId.isNotEmpty) {
      final mapped =
          exploreFloods.indexWhere((post) => post.docID == pendingDocId);
      if (mapped >= 0) return mapped;
    }
    if (lastFloodVisibleIndex != null &&
        lastFloodVisibleIndex! >= 0 &&
        lastFloodVisibleIndex! < exploreFloods.length) {
      return lastFloodVisibleIndex!;
    }
    if (floodsVisibleIndex.value >= 0 &&
        floodsVisibleIndex.value < exploreFloods.length) {
      return floodsVisibleIndex.value;
    }
    return 0;
  }

  void _performRestoreFloodSeriesFocus() {
    final target = _performResolveFloodSeriesFocusIndex();
    if (target < 0 || target >= exploreFloods.length) return;
    floodsVisibleIndex.value = target;
    lastFloodVisibleIndex = target;
    _performScheduleExploreFloodPrefetchFromVisible(preferredIndex: target);
    _performFetchFloodsIfNearVisibleEnd(preferredIndex: target);
  }

  void _performScheduleExploreFloodPrefetchFromVisible({
    int? preferredIndex,
  }) {
    if (exploreFloods.isEmpty) return;
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null) return;

    final focusIndex = (preferredIndex ?? _performResolveFloodSeriesFocusIndex())
        .clamp(0, exploreFloods.length - 1);
    final maxPreparedStart = (((focusIndex + 1) ~/ _exploreFloodPrefetchChunkSize)
            * _exploreFloodPrefetchChunkSize)
        .clamp(0, exploreFloods.length - 1);

    for (var chunkStart = 0;
        chunkStart <= maxPreparedStart;
        chunkStart += _exploreFloodPrefetchChunkSize) {
      if (!_preparedFloodChildChunkStarts.add(chunkStart)) {
        continue;
      }
      final endExclusive = (chunkStart + _exploreFloodPrefetchChunkSize)
          .clamp(0, exploreFloods.length);
      final windowedPosts = exploreFloods.sublist(chunkStart, endExclusive);
      for (final post in windowedPosts) {
        _performBoostFloodChildFirstSegments(
          post,
          prefetch: prefetch,
        );
      }
    }
  }

  void _performFetchFloodsIfNearVisibleEnd({
    int? preferredIndex,
  }) {
    if (floodsIsLoading.value ||
        !floodsHasMore.value ||
        exploreFloods.isEmpty) {
      return;
    }
    if (exploreFloods.length >= _exploreFloodListMaxItems) {
      floodsHasMore.value = false;
      return;
    }
    final focusIndex = preferredIndex ?? _performResolveFloodSeriesFocusIndex();
    if (focusIndex < 0 || focusIndex >= exploreFloods.length) return;

    final remainingAfterVisible = exploreFloods.length - focusIndex - 1;
    if (remainingAfterVisible > _exploreFloodFetchTriggerTailCount) {
      return;
    }

    unawaited(fetchFloods());
  }

  void _performBoostFloodChildFirstSegments(
    PostsModel rootPost, {
    required PrefetchScheduler prefetch,
  }) {
    final floodCount = rootPost.floodCount.toInt();
    if (floodCount <= 1) {
      prefetch.boostDoc(rootPost.docID, readySegments: 1);
      return;
    }

    final baseId = rootPost.docID.replaceFirst(RegExp(r'_\d+$'), '');
    for (var i = 0; i < floodCount; i++) {
      prefetch.boostDoc('${baseId}_$i', readySegments: 1);
    }
  }

  void _performResetFloodChildPrefetchPlan() {
    _preparedFloodChildChunkStarts.clear();
  }

  void _performCapturePendingFloodEntry({
    int? preferredIndex,
    PostsModel? model,
  }) {
    if (model != null) {
      final docId = model.docID.trim();
      _pendingFloodDocId = docId.isEmpty ? null : docId;
      return;
    }
    final candidateIndex = preferredIndex ??
        (floodsVisibleIndex.value >= 0
            ? floodsVisibleIndex.value
            : lastFloodVisibleIndex);
    if (candidateIndex == null ||
        candidateIndex < 0 ||
        candidateIndex >= exploreFloods.length) {
      _pendingFloodDocId = null;
      return;
    }
    final docId = exploreFloods[candidateIndex].docID.trim();
    _pendingFloodDocId = docId.isEmpty ? null : docId;
  }

  void _performSuspendExplorePreview({required int focusIndex}) {
    explorePreviewSuspended.value = true;
    explorePreviewFocusIndex.value = focusIndex;
  }

  void _performResumeExplorePreview() {
    explorePreviewSuspended.value = false;
  }

  void _performShuffleExplorePosts() {
    if (explorePosts.length < 2) return;
    final shuffled = List<PostsModel>.from(explorePosts)..shuffle();
    explorePreviewFocusIndex.value = -1;
    explorePosts.assignAll(shuffled);
  }

  void _performBindFollowingListener() {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    _fetchFollowingIDs(uid);
  }

  Future<void> _performFetchFollowingIDs(String uid) async {
    try {
      final ids = await _visibilityPolicy.loadViewerFollowingIds(
        viewerUserId: uid,
        preferCache: true,
      );
      followingIDs.assignAll(ids);
    } catch (_) {}
  }

  Future<void> _performFetchExplorePosts({
    bool forceRefresh = false,
  }) async {
    final mirrored = await _performSyncExploreFromShorts(
      ensureReady: !forceRefresh,
      forceRefresh: forceRefresh,
      nearEnd: explorePosts.isNotEmpty && !forceRefresh,
    );
    if (mirrored) {
      return;
    }
    if (exploreIsLoading.value || !exploreHasMore.value) return;
    exploreIsLoading.value = true;
    try {
      if (lastExploreDoc == null) _exploreEmptyScans = 0;
      int pagesFetched = 0;
      const int pageLimit = ReadBudgetRegistry.explorePostsPageLimit;
      final isBootstrapTopUp =
          lastExploreDoc == null && explorePosts.isNotEmpty;
      final int maxPages = isBootstrapTopUp
          ? ReadBudgetRegistry.explorePostsBootstrapMaxPages
          : ReadBudgetRegistry.explorePostsMaxPages;
      final int targetBatch = isBootstrapTopUp
          ? ReadBudgetRegistry.explorePostsBootstrapTargetBatch
          : ReadBudgetRegistry.explorePostsTargetBatch;
      List<PostsModel> accumulated = [];
      while (pagesFetched < maxPages && exploreHasMore.value) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final page = await _exploreRepository.fetchExplorePostsPage(
          startAfter: lastExploreDoc,
          pageLimit: pageLimit,
          nowMs: nowMs,
        );
        if (page.items.isEmpty) {
          exploreHasMore.value = false;
          break;
        }
        if (!page.hasMore) exploreHasMore.value = false;
        lastExploreDoc = page.lastDoc;

        var newPosts = page.items;
        newPosts = newPosts.where(_isEligibleExplorePost).toList();
        newPosts = newPosts
            .where((p) => p.timeStamp <= nowMs)
            .where((p) => p.deletedPost != true)
            .toList();
        newPosts = await _filterByPrivacy(newPosts);

        if (newPosts.isNotEmpty) {
          accumulated.addAll(newPosts);
          if (accumulated.length >= targetBatch) {
            break;
          }
        }

        pagesFetched++;
      }

      if (accumulated.isNotEmpty) {
        final existingIds = explorePosts.map((e) => e.docID).toSet();
        final existingCanonicalIds =
            explorePosts.map(_exploreCanonicalId).toSet();
        final uniqueAccumulated = <PostsModel>[];
        final seen = <String>{};
        for (final post in accumulated) {
          if (existingIds.contains(post.docID)) continue;
          final canonicalId = _exploreCanonicalId(post);
          if (existingCanonicalIds.contains(canonicalId)) continue;
          if (!seen.add(canonicalId)) continue;
          uniqueAccumulated.add(post);
        }

        final prioritized = _prioritizeCachedVideos(uniqueAccumulated);
        explorePosts.addAll(prioritized);
        _scheduleExplorePrefetchFromPosts(explorePosts);
        unawaited(_saveExplorePostsToPool(prioritized));
        _exploreEmptyScans = 0;
      } else if (pagesFetched >= maxPages && exploreHasMore.value) {
        exploreHasMore.value = false;
      } else {
        _exploreEmptyScans++;
        if (_exploreEmptyScans >= 3) {
          exploreHasMore.value = false;
        }
      }
    } catch (_) {}
    exploreIsLoading.value = false;
  }

  Future<void> _performPrepareStartupSurface({
    bool? allowBackgroundRefresh,
  }) {
    final active = _startupPrepareFuture;
    if (active != null) {
      return active;
    }

    final future = _performRunPrepareStartupSurface(
      allowBackgroundRefresh: allowBackgroundRefresh,
    );
    _startupPrepareFuture = future;
    future.whenComplete(() {
      if (identical(_startupPrepareFuture, future)) {
        _startupPrepareFuture = null;
      }
    });
    return future;
  }

  Future<void> _performRunPrepareStartupSurface({
    bool? allowBackgroundRefresh,
  }) async {
    try {
      final allowRefresh = allowBackgroundRefresh ??
          ContentPolicy.allowBackgroundRefresh(ContentScreenKind.explore);

      await _performHydrateExploreStartupShard();
      await _performWarmTrendingTagsForStartup();
      if (await _performSyncExploreFromShorts(ensureReady: true)) {
        return;
      }
      await _tryQuickFillExploreFromPool();
      _scheduleExplorePrefetchFromPosts(explorePosts);

      final hasLocalContent =
          trendingTags.isNotEmpty || explorePosts.isNotEmpty;

      if (trendingTags.isEmpty &&
          ContentPolicy.shouldBootstrapNetwork(
            ContentScreenKind.explore,
            hasLocalContent: hasLocalContent,
          )) {
        await fetchTrendingTags();
      }

      if (explorePosts.isEmpty) {
        if (ContentPolicy.shouldBootstrapNetwork(
          ContentScreenKind.explore,
          hasLocalContent: trendingTags.isNotEmpty || explorePosts.isNotEmpty,
        )) {
          if (trendingTags.isNotEmpty && !allowRefresh) {
            return;
          }
          await fetchExplorePosts();
        }
        return;
      }

      if (allowRefresh) {
        unawaited(fetchExplorePosts());
      }
    } finally {
      unawaited(_persistExploreStartupShard());
      unawaited(_recordExploreStartupSurface());
    }
  }

  Future<void> _performHydrateExploreStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    _startupShardHydrated = false;
    _startupShardAgeMs = null;
    try {
      final shard = await ensureStartupSnapshotShardStore().load(
        surface: 'explore',
        userId: userId,
        maxAge: StartupSnapshotShardStore.defaultFreshWindow,
      );
      if (shard == null) return;
      var didHydrate = false;
      if (trendingTags.isEmpty) {
        final decodedTags =
            _decodeExploreStartupTags(shard.payload['trendingTags']);
        if (decodedTags.isNotEmpty) {
          trendingTags.assignAll(decodedTags);
          didHydrate = true;
        }
      }
      if (explorePosts.isEmpty) {
        final decodedPosts =
            _decodeExploreStartupPosts(shard.payload['explorePosts']);
        if (decodedPosts.isNotEmpty) {
          explorePosts.assignAll(decodedPosts);
          _scheduleExplorePrefetchFromPosts(explorePosts);
          didHydrate = true;
        }
      }
      if (!didHydrate) return;
      _startupShardHydrated = true;
      _startupShardAgeMs =
          DateTime.now().millisecondsSinceEpoch - shard.savedAtMs;
    } catch (_) {}
  }

  Future<void> _performWarmTrendingTagsForStartup() async {
    if (trendingTags.isNotEmpty) return;
    try {
      final cached = await _topTagsRepository.readTrendingTagsCache(
        resultLimit: ReadBudgetRegistry.exploreTrendingTagsLimit,
      );
      if (cached == null || cached.isEmpty) return;
      trendingTags.assignAll(cached);
    } catch (_) {}
  }

  Future<void> _persistExploreStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final payload = <String, dynamic>{
      'trendingTags': _encodeExploreStartupTags(
        trendingTags
            .take(ReadBudgetRegistry.exploreStartupTagsShardLimit)
            .toList(),
      ),
      'explorePosts': _encodeExploreStartupPosts(
        explorePosts
            .take(ReadBudgetRegistry.exploreStartupPostsShardLimit)
            .toList(),
      ),
    };
    final itemCount = trendingTags.length + explorePosts.length;
    final hasData = (payload['trendingTags'] as List).isNotEmpty ||
        (payload['explorePosts'] as Map<String, dynamic>)['items'] is List &&
            ((payload['explorePosts'] as Map<String, dynamic>)['items'] as List)
                .isNotEmpty;
    try {
      final store = ensureStartupSnapshotShardStore();
      if (!hasData) {
        await store.clear(
          surface: 'explore',
          userId: userId,
        );
        return;
      }
      await store.save(
        surface: 'explore',
        userId: userId,
        itemCount: itemCount,
        limit: ReadBudgetRegistry.exploreStartupShardLimit,
        source: trendingTags.isNotEmpty ? 'top_tags_cache' : 'index_pool',
        payload: payload,
      );
    } catch (_) {}
  }

  Future<void> _recordExploreStartupSurface() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final hasLocalSnapshot = trendingTags.isNotEmpty || explorePosts.isNotEmpty;
    final source = trendingTags.isNotEmpty
        ? 'top_tags_cache'
        : explorePosts.isNotEmpty
            ? 'index_pool'
            : 'none';
    final itemCount =
        trendingTags.isNotEmpty ? trendingTags.length : explorePosts.length;
    try {
      await ensureStartupSnapshotManifestStore().recordSurfaceState(
        surface: 'explore',
        userId: userId,
        itemCount: itemCount,
        hasLocalSnapshot: hasLocalSnapshot,
        source: source,
        startupShardHydrated: _startupShardHydrated,
        startupShardAgeMs: _startupShardAgeMs,
      );
    } catch (_) {}
  }

  List<Map<String, dynamic>> _encodeExploreStartupTags(
      List<HashtagModel> tags) {
    return tags
        .map(
          (tag) => <String, dynamic>{
            'hashtag': tag.hashtag,
            'count': tag.count,
            'hasHashtag': tag.hasHashtag,
            'lastSeenTs': tag.lastSeenTs,
          },
        )
        .toList(growable: false);
  }

  List<HashtagModel> _decodeExploreStartupTags(dynamic raw) {
    if (raw is! List) return const <HashtagModel>[];
    return raw
        .whereType<Map>()
        .map((entry) {
          final map = Map<String, dynamic>.from(entry.cast<dynamic, dynamic>());
          final hashtag = (map['hashtag'] ?? '').toString().trim();
          if (hashtag.isEmpty) return null;
          return HashtagModel(
            hashtag,
            (map['count'] as num?) ?? 0,
            hasHashtag: map['hasHashtag'] == true,
            lastSeenTs: (map['lastSeenTs'] as num?)?.toInt(),
          );
        })
        .whereType<HashtagModel>()
        .toList(growable: false);
  }

  Map<String, dynamic> _encodeExploreStartupPosts(List<PostsModel> posts) {
    final payload = <String, dynamic>{
      'items': posts
          .map(
            (post) => <String, dynamic>{
              'docID': post.docID,
              'data': post.toMap(),
            },
          )
          .toList(growable: false),
    };
    final posterHints = TurqImageCacheManager.buildPosterHintsForPosts(posts);
    if (posterHints.isNotEmpty) {
      payload[TurqImageCacheManager.startupPosterHintsKey] = posterHints;
    }
    return payload;
  }

  List<PostsModel> _decodeExploreStartupPosts(dynamic raw) {
    if (raw is! Map) return const <PostsModel>[];
    TurqImageCacheManager.hydratePosterHintsFromPayload(
      Map<String, dynamic>.from(raw.cast<dynamic, dynamic>()),
    );
    final items = raw['items'];
    if (items is! List) return const <PostsModel>[];
    return items
        .whereType<Map>()
        .map((entry) {
          final map = Map<String, dynamic>.from(entry.cast<dynamic, dynamic>());
          final docId = (map['docID'] ?? '').toString().trim();
          final data = map['data'];
          if (docId.isEmpty || data is! Map) return null;
          try {
            return PostsModel.fromMap(
              Map<String, dynamic>.from(data.cast<dynamic, dynamic>()),
              docId,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<PostsModel>()
        .toList(growable: false);
  }

  Future<void> _performTryQuickFillExploreFromPool() async {
    final pool = IndexPoolStore.maybeFind();
    if (pool == null) return;
    final fromPool = await pool.loadPosts(
      IndexPoolKind.explore,
      limit: ContentPolicy.initialPoolLimit(ContentScreenKind.explore),
      allowStale: true,
    );
    if (fromPool.isEmpty) return;
    final profiles = await _loadDiscoveryProfiles(
      fromPool.map((e) => e.userID).toSet(),
      preferCache: true,
      cacheOnly: true,
    );
    final filtered = fromPool
        .where(_isEligibleExplorePost)
        .where((p) => p.deletedPost != true)
        .where((p) {
      final profile = profiles[p.userID];
      if (profile == null) return false;
      final isDeactivated = isDeactivatedAccount(
        accountStatus: profile['accountStatus'],
        isDeleted: profile['isDeleted'],
      );
      if (isDeactivated) return false;
      final rozet =
          (profile['rozet'] ?? profile['badge'] ?? p.rozet).toString().trim();
      final isApproved = profile['isApproved'] == true;
      return _visibilityPolicy.canViewerSeeDiscoveryAuthorFromSummary(
        authorUserId: p.userID,
        followingIds: followingIDs,
        rozet: rozet,
        isApproved: isApproved,
        isDeleted: false,
      );
    }).toList();
    if (filtered.isEmpty) return;
    final valid = _dedupeExplorePosts(filtered);
    if (valid.isEmpty) return;
    explorePosts.assignAll(valid);
    _scheduleExplorePrefetchFromPosts(explorePosts);
    if (ContentPolicy.allowBackgroundRefresh(ContentScreenKind.explore)) {
      unawaited(_cleanupExplorePoolFill(valid));
    }
  }

  Future<void> _performCleanupExplorePoolFill(List<PostsModel> shown) async {
    try {
      final valid =
          _dedupeExplorePosts(await _validatePoolPostsAndPrune(shown));
      if (valid.length == shown.length) return;
      final validIds = valid.map((e) => e.docID).toSet();
      final shownIds = shown.map((e) => e.docID).toSet();
      explorePosts.removeWhere(
        (post) =>
            shownIds.contains(post.docID) && !validIds.contains(post.docID),
      );
    } catch (_) {}
  }

  Future<void> _performSaveExplorePostsToPool(List<PostsModel> posts) async {
    if (posts.isEmpty) return;
    await IndexPoolStore.maybeFind()?.savePosts(IndexPoolKind.explore, posts);
  }

  bool _performIsEligibleExplorePost(PostsModel post) {
    return post.hasPlayableVideo &&
        post.originalPostID.trim().isEmpty &&
        post.aspectRatio.toDouble() < _verticalExploreAspectMax;
  }

  String _performExploreCanonicalId(PostsModel post) {
    final original = post.originalPostID.trim();
    if (original.isNotEmpty) return original;
    return post.docID;
  }

  List<PostsModel> _performDedupeExplorePosts(List<PostsModel> posts) {
    final seen = <String>{};
    final out = <PostsModel>[];
    for (final post in posts) {
      final canonicalId = _exploreCanonicalId(post);
      if (!seen.add(canonicalId)) continue;
      out.add(post);
    }
    return out;
  }

  Future<List<PostsModel>> _performValidatePoolPostsAndPrune(
    List<PostsModel> posts,
  ) async {
    if (posts.isEmpty) return const <PostsModel>[];
    final pool = IndexPoolStore.maybeFind();
    if (pool == null) return posts;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final postIds =
        posts.map((e) => e.docID).where((e) => e.isNotEmpty).toSet().toList();
    final userIds =
        posts.map((e) => e.userID).where((e) => e.isNotEmpty).toSet();

    final validPostIds = <String>{};
    final postMap = await _exploreRepository.fetchPostsByIds(
      postIds,
      preferCache: true,
    );
    for (final entry in postMap.entries) {
      final post = entry.value;
      if (post.deletedPost == true) continue;
      if (post.arsiv == true) continue;
      if (post.timeStamp > nowMs) continue;
      validPostIds.add(entry.key);
    }

    final profiles = await _userCache.getProfiles(
      userIds.toList(),
      preferCache: true,
      cacheOnly: !ContentPolicy.isConnected,
    );
    final validUserIds = profiles.keys.toSet();

    final valid = posts
        .where(
          (post) =>
              validPostIds.contains(post.docID) &&
              validUserIds.contains(post.userID),
        )
        .toList();

    if (valid.length != posts.length) {
      final invalidIds = posts
          .where(
            (post) =>
                !validPostIds.contains(post.docID) ||
                !validUserIds.contains(post.userID),
          )
          .map((post) => post.docID)
          .toList();
      if (invalidIds.isNotEmpty) {
        await pool.removePosts(IndexPoolKind.explore, invalidIds);
      }
    }
    return valid;
  }

  Future<void> _performFetchTrendingTags({
    bool forceRefresh = false,
  }) async {
    try {
      final tags = await _topTagsRepository.fetchTrendingTags(
        resultLimit: ReadBudgetRegistry.exploreTrendingTagsLimit,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (tags.isEmpty && trendingTags.isNotEmpty) {
        return;
      }
      trendingTags.assignAll(tags);
    } catch (_) {}
  }

  Future<void> _performFetchVideo() async {
    if (videoIsLoading.value || !videoHasMore.value) return;
    videoIsLoading.value = true;
    try {
      if (lastVideoDoc == null) _videoEmptyScans = 0;
      int pagesFetched = 0;
      const int maxPages = ReadBudgetRegistry.exploreVideoMaxPages;
      const int targetBatch = ReadBudgetRegistry.exploreVideoTargetBatch;
      List<PostsModel> accumulated = [];
      while (pagesFetched < maxPages && videoHasMore.value) {
        const int pageLimit = ReadBudgetRegistry.exploreVideoPageLimit;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        ExploreQueryPage page;
        try {
          page = await _exploreRepository.fetchVideoReadyPage(
            startAfter: lastVideoDoc,
            pageLimit: pageLimit,
            nowMs: nowMs,
          );
        } catch (e) {
          final isIndexError = e is FirebaseException
              ? e.code == 'failed-precondition'
              : e.toString().contains('requires an index');
          if (!isIndexError) rethrow;

          try {
            page = await _exploreRepository.fetchVideoFallbackPage(
              startAfter: lastVideoDoc,
              pageLimit: pageLimit,
              nowMs: nowMs,
            );
          } catch (_) {
            page = await _exploreRepository.fetchVideoBroadPage(
              startAfter: lastVideoDoc,
              pageLimit: pageLimit,
              nowMs: nowMs,
            );
          }
        }
        if (page.items.isEmpty) {
          videoHasMore.value = false;
          break;
        }
        if (!page.hasMore) videoHasMore.value = false;
        lastVideoDoc = page.lastDoc;

        var newVideos = page.items;
        newVideos = newVideos
            .where((post) => post.hasPlayableVideo)
            .where((post) => post.flood == false)
            .toList();
        newVideos = newVideos
            .where((post) => post.timeStamp <= nowMs)
            .where((post) => post.deletedPost != true)
            .toList();
        newVideos = await _filterByPrivacy(newVideos);
        if (newVideos.isNotEmpty) {
          accumulated.addAll(newVideos);
          if (accumulated.length >= targetBatch) {
            break;
          }
        }
        pagesFetched++;
      }

      if (accumulated.isNotEmpty) {
        final prioritized = _prioritizeCachedVideos(accumulated);
        exploreVideos.addAll(prioritized);
        _scheduleExplorePrefetchFromPosts(exploreVideos);
        _videoEmptyScans = 0;
        if (pagesFetched >= maxPages && videoHasMore.value) {
          videoHasMore.value = false;
        }
      } else if (pagesFetched >= maxPages && videoHasMore.value) {
        videoHasMore.value = false;
      } else {
        _videoEmptyScans++;
        if (_videoEmptyScans >= 3) {
          videoHasMore.value = false;
        }
      }
    } catch (_) {}
    videoIsLoading.value = false;
  }

  Future<void> _performFetchPhoto() async {
    if (photoIsLoading.value || !photoHasMore.value) return;
    photoIsLoading.value = true;
    try {
      if (lastPhotoDoc == null) _photoEmptyScans = 0;
      int pagesFetched = 0;
      const int maxPages = ReadBudgetRegistry.explorePhotoMaxPages;
      const int pageLimit = ReadBudgetRegistry.explorePhotoPageLimit;
      List<PostsModel> accumulated = [];
      while (pagesFetched < maxPages && photoHasMore.value) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final page = await _exploreRepository.fetchPhotoPage(
          startAfter: lastPhotoDoc,
          pageLimit: pageLimit,
          nowMs: nowMs,
        );
        if (page.items.isEmpty) {
          photoHasMore.value = false;
          break;
        }
        if (!page.hasMore) photoHasMore.value = false;
        lastPhotoDoc = page.lastDoc;

        List<PostsModel> newPhotos = [];
        for (final model in page.items) {
          if (model.metin != "" && model.img.isNotEmpty) {
            newPhotos.add(model);
          }
        }
        newPhotos = newPhotos
            .where((post) => post.timeStamp <= nowMs)
            .where((post) => post.deletedPost != true)
            .toList();
        newPhotos = await _filterByPrivacy(newPhotos);
        if (newPhotos.isNotEmpty) {
          accumulated.addAll(newPhotos);
          if (accumulated.length >=
              ReadBudgetRegistry.explorePhotoTargetBatch) {
            break;
          }
        }
        pagesFetched++;
      }

      if (accumulated.isNotEmpty) {
        explorePhotos.addAll(accumulated);
        _photoEmptyScans = 0;
        if (pagesFetched >= maxPages && photoHasMore.value) {
          photoHasMore.value = false;
        }
      } else if (pagesFetched >= maxPages && photoHasMore.value) {
        photoHasMore.value = false;
      } else {
        _photoEmptyScans++;
        if (_photoEmptyScans >= 3) {
          photoHasMore.value = false;
        }
      }
    } catch (_) {}
    photoIsLoading.value = false;
  }

  Future<void> _performFetchFloods() async {
    if (floodsIsLoading.value || !floodsHasMore.value) return;
    if (exploreFloods.length >= _exploreFloodListMaxItems) {
      floodsHasMore.value = false;
      return;
    }
    floodsIsLoading.value = true;
    capturePendingFloodEntry();
    try {
      if (lastFloodsDoc == null) _floodsEmptyScans = 0;
      int pagesFetched = 0;
      const int maxPages = ReadBudgetRegistry.explorePostsMaxPages;
      const int pageLimit = _exploreFloodListBatchSize;
      const int targetBatch = _exploreFloodListBatchSize;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      List<PostsModel> accumulated = [];
      bool noMoreServerPages = false;
      final existingIDs = exploreFloods.map((e) => e.docID).toSet();
      final int remainingSlots =
          (_exploreFloodListMaxItems - exploreFloods.length)
              .clamp(0, targetBatch);
      if (remainingSlots <= 0) {
        floodsHasMore.value = false;
        return;
      }

      while (pagesFetched < maxPages && !noMoreServerPages) {
        ExploreQueryPage page;
        try {
          page = await _exploreRepository.fetchFloodServerPage(
            startAfter: lastFloodsDoc,
            pageLimit: pageLimit,
          );
        } catch (_) {
          page = await _exploreRepository.fetchFloodFallbackPage(
            startAfter: lastFloodsDoc,
            pageLimit: pageLimit,
            nowMs: nowMs,
          );
        }
        if (page.items.isEmpty) {
          noMoreServerPages = true;
          break;
        }
        if (!page.hasMore) noMoreServerPages = true;
        lastFloodsDoc = page.lastDoc;

        List<PostsModel> batch = [];
        for (final model in page.items) {
          if (model.flood == true) {
            continue;
          }
          if (model.floodCount <= 1) {
            continue;
          }
          if (existingIDs.contains(model.docID)) {
            continue;
          }
          batch.add(model);
        }
        batch = batch
            .where((post) => post.timeStamp <= nowMs)
            .where((post) => post.deletedPost != true)
            .toList();
        batch = await _filterByPrivacy(batch);
        if (batch.isNotEmpty) {
          accumulated.addAll(batch);
          if (accumulated.length >= remainingSlots) {
            break;
          }
        }
        pagesFetched++;
      }

      if (accumulated.isNotEmpty) {
        final boundedAccumulated = accumulated.length > remainingSlots
            ? accumulated.take(remainingSlots).toList(growable: false)
            : accumulated;
        final prioritized = _prioritizeCachedVideos(boundedAccumulated);
        if (exploreFloods.isEmpty) {
          _performResetFloodChildPrefetchPlan();
        }
        exploreFloods.addAll(prioritized);
        _performRestoreFloodSeriesFocus();
        _performScheduleExploreFloodPrefetchFromVisible();
        _floodsEmptyScans = 0;
        floodsHasMore.value = !noMoreServerPages &&
            exploreFloods.length < _exploreFloodListMaxItems;
      } else {
        _floodsEmptyScans++;
        if (_floodsEmptyScans >= 2 || noMoreServerPages) {
          floodsHasMore.value = false;
        }
      }
    } catch (_) {}
    floodsIsLoading.value = false;
  }

  Future<List<PostsModel>> _performFilterByPrivacy(
    List<PostsModel> items,
  ) async {
    if (items.isEmpty) return items;
    final userProfiles = await _loadDiscoveryProfiles(
      items.map((e) => e.userID).toSet(),
      preferCache: true,
      cacheOnly: !ContentPolicy.isConnected,
    );
    return items.where((post) {
      final data = userProfiles[post.userID];
      final rozet =
          (data?['rozet'] ?? data?['badge'] ?? post.rozet).toString().trim();
      final isApproved = data?['isApproved'] == true;
      return _visibilityPolicy.canViewerSeeDiscoveryAuthorFromSummary(
        authorUserId: post.userID,
        followingIds: followingIDs,
        rozet: rozet,
        isApproved: isApproved,
        isDeleted: false,
      );
    }).toList();
  }

  Future<Map<String, Map<String, dynamic>>> _loadDiscoveryProfiles(
    Set<String> userIds, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    if (userIds.isEmpty) return const <String, Map<String, dynamic>>{};
    final cached = await _userCache.getProfiles(
      userIds.toList(growable: false),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    if (cacheOnly) return cached;

    final viewerUid = CurrentUserService.instance.effectiveUserId.trim();
    final refreshIds = userIds.where((userId) {
      final uid = userId.trim();
      if (uid.isEmpty) return false;
      if (viewerUid.isNotEmpty && uid == viewerUid) return false;
      if (followingIDs.contains(uid)) return false;
      final profile = cached[uid];
      final rozet =
          (profile?['rozet'] ?? profile?['badge'] ?? '').toString().trim();
      final isApproved = profile?['isApproved'] == true;
      final isDeleted = profile?['isDeleted'] == true;
      if (isDeleted) return false;
      if (profile == null) return true;
      return !isDiscoveryPublicAuthor(
        rozet: rozet,
        isApproved: isApproved,
      );
    }).toList(growable: false);
    if (refreshIds.isEmpty) return cached;

    final fresh = await _userCache.getProfiles(
      refreshIds,
      preferCache: false,
      cacheOnly: false,
    );
    if (fresh.isEmpty) return cached;
    return <String, Map<String, dynamic>>{...cached, ...fresh};
  }

  List<PostsModel> _performPrioritizeCachedVideos(List<PostsModel> items) {
    if (items.isEmpty) {
      return items;
    }

    final cache = SegmentCacheManager.maybeFind();
    if (cache == null) return items;
    final sorted = List<PostsModel>.from(items);

    int cacheScore(PostsModel post) {
      if (!post.hasPlayableVideo) return -1;
      final entry = cache.getEntry(post.docID);
      if (entry == null || entry.cachedSegmentCount <= 0) return 0;
      if (entry.isFullyCached) return 3;
      if (entry.cachedSegmentCount >= 2) return 2;
      return 1;
    }

    int cachedSegments(PostsModel post) {
      if (!post.hasPlayableVideo) return 0;
      return cache.getEntry(post.docID)?.cachedSegmentCount ?? 0;
    }

    sorted.sort((a, b) {
      final scoreCompare = cacheScore(b).compareTo(cacheScore(a));
      if (scoreCompare != 0) return scoreCompare;

      final segCompare = cachedSegments(b).compareTo(cachedSegments(a));
      if (segCompare != 0) return segCompare;

      return b.timeStamp.compareTo(a.timeStamp);
    });

    return sorted;
  }

  void _performScheduleExplorePrefetchFromPosts(List<PostsModel> source) {
    if (source.isEmpty) return;
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null) return;

    unawaited(prefetch.updateQueueForPosts(
      source,
      0,
      maxDocs: ReadBudgetRegistry.explorePrefetchDocLimit,
    ));
  }

  void _performGoToPage(int index) {
    selection.value = index;
    if (index == 0 && trendingTags.isEmpty) {
      fetchTrendingTags();
    } else if (index == 1 && explorePosts.isEmpty && !exploreIsLoading.value) {
      fetchExplorePosts();
    } else if (index == 2 && exploreFloods.isEmpty && !floodsIsLoading.value) {
      fetchFloods();
    } else if (index == 2) {
      _performScheduleExploreFloodPrefetchFromVisible();
      _performFetchFloodsIfNearVisibleEnd();
    }

    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
