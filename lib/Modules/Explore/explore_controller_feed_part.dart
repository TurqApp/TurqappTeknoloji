part of 'explore_controller.dart';

extension ExploreControllerFeedPart on ExploreController {
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
    final target = resolveFloodSeriesFocusIndex();
    if (target < 0 || target >= exploreFloods.length) return;
    floodsVisibleIndex.value = target;
    lastFloodVisibleIndex = target;
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

  Future<void> _performFetchExplorePosts() async {
    if (exploreIsLoading.value || !exploreHasMore.value) return;
    exploreIsLoading.value = true;
    try {
      if (lastExploreDoc == null) _exploreEmptyScans = 0;
      int pagesFetched = 0;
      const int pageLimit = 20;
      final isBootstrapTopUp =
          lastExploreDoc == null && explorePosts.isNotEmpty;
      final int maxPages = isBootstrapTopUp ? 4 : 10;
      final int targetBatch = isBootstrapTopUp ? 12 : 24;
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
          newPosts.shuffle();
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

  Future<void> _performQuickFillExploreFromPoolAndBootstrap() async {
    await _tryQuickFillExploreFromPool();
    _scheduleExplorePrefetchFromPosts(explorePosts);
    if (explorePosts.isEmpty) {
      if (ContentPolicy.shouldBootstrapNetwork(
        ContentScreenKind.explore,
        hasLocalContent: false,
      )) {
        await fetchExplorePosts();
      }
    } else if (ContentPolicy.allowBackgroundRefresh(
      ContentScreenKind.explore,
    )) {
      unawaited(fetchExplorePosts());
    }
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
    final profiles = await _userCache.getProfiles(
      fromPool.map((e) => e.userID).toSet().toList(),
      preferCache: true,
      cacheOnly: true,
    );
    final filtered = fromPool
        .where(_isEligibleExplorePost)
        .where((p) => p.deletedPost != true)
        .where((p) {
      final profile = profiles[p.userID];
      if (profile == null) return false;
      final isPrivate = (profile['isPrivate'] ?? false) == true;
      final isDeactivated = isDeactivatedAccount(
        accountStatus: profile['accountStatus'],
        isDeleted: profile['isDeleted'],
      );
      if (isDeactivated) return false;
      return _visibilityPolicy.canViewerSeeAuthorFromSummary(
        authorUserId: p.userID,
        followingIds: followingIDs,
        isPrivate: isPrivate,
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
        post.aspectRatio.toDouble() <
            ExploreController._verticalExploreAspectMax;
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

  Future<void> _performFetchTrendingTags() async {
    try {
      final tags = await _topTagsRepository.fetchTrendingTags(
        resultLimit: 30,
        preferCache: true,
      );
      trendingTags.assignAll(tags);
    } catch (_) {
      trendingTags.clear();
    }
  }

  Future<void> _performFetchVideo() async {
    if (videoIsLoading.value || !videoHasMore.value) return;
    videoIsLoading.value = true;
    try {
      if (lastVideoDoc == null) _videoEmptyScans = 0;
      int pagesFetched = 0;
      const int maxPages = 10;
      const int targetBatch = 24;
      List<PostsModel> accumulated = [];
      while (pagesFetched < maxPages && videoHasMore.value) {
        const int pageLimit = 30;
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
          newVideos.shuffle();
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
      const int maxPages = 5;
      const int pageLimit = 20;
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
          newPhotos.shuffle();
          accumulated.addAll(newPhotos);
          if (accumulated.length >= 30) {
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
    floodsIsLoading.value = true;
    capturePendingFloodEntry();
    try {
      if (lastFloodsDoc == null) _floodsEmptyScans = 0;
      int pagesFetched = 0;
      const int maxPages = 10;
      const int pageLimit = 60;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      List<PostsModel> accumulated = [];
      bool noMoreServerPages = false;
      final existingIDs = exploreFloods.map((e) => e.docID).toSet();

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
          batch.shuffle();
          accumulated.addAll(batch);
          if (accumulated.length >= 30) {
            break;
          }
        }
        pagesFetched++;
      }

      if (accumulated.isNotEmpty) {
        final prioritized = _prioritizeCachedVideos(accumulated);
        exploreFloods.addAll(prioritized);
        restoreFloodSeriesFocus();
        _floodsEmptyScans = 0;
        floodsHasMore.value = !noMoreServerPages;
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
    final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();
    final userProfiles = await _userCache.getProfiles(
      uniqueUserIDs,
      preferCache: true,
      cacheOnly: !ContentPolicy.isConnected,
    );
    final userPrivacy = <String, bool>{};
    for (final uid in uniqueUserIDs) {
      final data = userProfiles[uid];
      userPrivacy[uid] = (data?['isPrivate'] ?? false) == true;
    }

    return items.where((post) {
      final isPrivate = userPrivacy[post.userID] ?? false;
      return _visibilityPolicy.canViewerSeeAuthorFromSummary(
        authorUserId: post.userID,
        followingIds: followingIDs,
        isPrivate: isPrivate,
        isDeleted: false,
      );
    }).toList();
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
    final prefetch = PrefetchScheduler.maybeFind();
    if (prefetch == null) return;

    final docIds = source
        .where((post) => post.hasPlayableVideo)
        .map((post) => post.docID)
        .where((id) => id.isNotEmpty)
        .take(20)
        .toList();
    if (docIds.isEmpty) return;

    unawaited(prefetch.updateQueue(docIds, 0));
  }

  void _performGoToPage(int index) {
    selection.value = index;
    if (index == 0 && trendingTags.isEmpty) {
      fetchTrendingTags();
    } else if (index == 1 && explorePosts.isEmpty && !exploreIsLoading.value) {
      fetchExplorePosts();
    } else if (index == 2 && exploreFloods.isEmpty && !floodsIsLoading.value) {
      fetchFloods();
    }

    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
