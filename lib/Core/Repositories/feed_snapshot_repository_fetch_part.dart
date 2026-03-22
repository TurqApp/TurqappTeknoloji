part of 'feed_snapshot_repository.dart';

extension FeedSnapshotRepositoryFetchPart on FeedSnapshotRepository {
  Future<FeedSourcePage> fetchHomePage({
    required String userId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    bool preferCache = true,
    bool cacheOnly = false,
    bool usePrimaryFeedPaging = true,
  }) async {
    final normalizedUserId = userId.trim();
    if (!usePrimaryFeedPaging || normalizedUserId.isEmpty) {
      return _loadLegacyPage(
        currentUserId: normalizedUserId,
        followingIds: followingIds,
        hiddenPostIds: hiddenPostIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        startAfter: startAfter,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
    }

    var refsPage = await _postRepository.fetchUserFeedReferences(
      uid: normalizedUserId,
      limit: limit,
      startAfter: startAfter,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );

    var refs = refsPage.items
        .where((item) => _isEligibleFeedReference(item, nowMs, cutoffMs))
        .toList(growable: false);

    if (kDebugMode) {
      debugPrint(
        '[FeedSnapshot] uid=$normalizedUserId startAfter=${startAfter?.id ?? ''} '
        'refs=${refsPage.items.length} eligible=${refs.length} limit=$limit',
      );
    }

    if (refs.isEmpty && startAfter == null) {
      final repaired = await _tryRepairHybridFeed(
        userId: normalizedUserId,
        limit: limit,
      );
      if (repaired) {
        refsPage = await _postRepository.fetchUserFeedReferences(
          uid: normalizedUserId,
          limit: limit,
          startAfter: null,
          preferCache: false,
          cacheOnly: false,
        );
        refs = refsPage.items
            .where((item) => _isEligibleFeedReference(item, nowMs, cutoffMs))
            .toList(growable: false);
        if (kDebugMode) {
          debugPrint(
            '[FeedSnapshot] uid=$normalizedUserId repairRefetch refs=${refsPage.items.length} '
            'eligible=${refs.length}',
          );
        }
      }
    }

    final postIds = refs.map((item) => item.postId).toList(growable: false);
    final postsById = postIds.isEmpty
        ? const <String, PostsModel>{}
        : await _postRepository.fetchPostCardsByIds(
            postIds,
            preferCache: preferCache,
            cacheOnly: cacheOnly,
          );

    final merged = <String, PostsModel>{};
    for (final ref in refs) {
      final post = postsById[ref.postId];
      if (post == null) continue;
      merged[post.docID] = post;
    }

    final celebIds = await _postRepository.fetchCelebrityAuthorIds(
      <String>{normalizedUserId, ...followingIds}.toList(growable: false),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    if (celebIds.isNotEmpty) {
      final celebPosts = await _postRepository.fetchRecentPostsForAuthors(
        celebIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        perAuthorLimit:
            max(2, (limit / celebIds.length.clamp(1, limit)).ceil()),
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      for (final post in celebPosts) {
        merged.putIfAbsent(post.docID, () => post);
      }
    }

    final publicScheduled = await _fetchVisiblePublicIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit < 20 ? 20 : limit,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    for (final post in publicScheduled) {
      merged.putIfAbsent(post.docID, () => post);
    }

    if (kDebugMode) {
      debugPrint(
        '[FeedSnapshot] uid=$normalizedUserId merged=${merged.length} '
        'celebAuthors=${celebIds.length} publicScheduled=${publicScheduled.length}',
      );
    }

    if (merged.isEmpty && refsPage.lastDoc == null && startAfter == null) {
      if (kDebugMode) {
        debugPrint(
          '[FeedSnapshot] uid=$normalizedUserId fallback=personal reason=primary_empty',
        );
      }
      final personalFallback = await _loadPersonalFallbackPage(
        currentUserId: normalizedUserId,
        followingIds: followingIds,
        hiddenPostIds: hiddenPostIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      if (personalFallback.items.isNotEmpty) {
        return personalFallback;
      }
      if (kDebugMode) {
        debugPrint(
          '[FeedSnapshot] uid=$normalizedUserId fallback=legacy reason=personal_empty',
        );
      }
      return _loadLegacyPage(
        currentUserId: normalizedUserId,
        followingIds: followingIds,
        hiddenPostIds: hiddenPostIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        startAfter: null,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
    }

    final visible = await filterVisiblePosts(
      merged.values.toList(growable: false),
      currentUserId: normalizedUserId,
      followingIds: followingIds,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
    );

    if (kDebugMode) {
      debugPrint(
        '[FeedSnapshot] uid=$normalizedUserId visible=${visible.length} '
        'sample=${visible.take(5).map((post) => post.docID).join(',')}',
      );
    }
    _invariantGuard.assertNotEmptyAfterRefresh(
      surface: 'feed',
      invariantKey: 'snapshot_visible_after_filter',
      hadSnapshot: merged.isNotEmpty,
      previousCount: merged.length,
      nextCount: visible.length,
      payload: <String, dynamic>{
        'uid': normalizedUserId,
        'refsCount': refs.length,
        'usesPrimaryFeed': true,
      },
    );

    return FeedSourcePage(
      items: visible,
      lastDoc: refsPage.lastDoc,
      usesPrimaryFeed: true,
    );
  }

  Future<FeedSourcePage> _loadPersonalFallbackPage({
    required String currentUserId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    if (currentUserId.isEmpty) {
      return const FeedSourcePage(
        items: <PostsModel>[],
        lastDoc: null,
        usesPrimaryFeed: false,
      );
    }

    final merged = <String, PostsModel>{};

    final ownPosts = await _postRepository.fetchRecentPostsForAuthors(
      <String>[currentUserId],
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      perAuthorLimit: limit,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    for (final post in ownPosts) {
      merged[post.docID] = post;
    }

    if (followingIds.isNotEmpty) {
      final followingSeed = followingIds.toList(growable: false);
      final perAuthorLimit = followingSeed.length > 150
          ? 1
          : followingSeed.length > 50
              ? 2
              : 3;
      final followingPosts = await _postRepository.fetchRecentPostsForAuthors(
        followingSeed,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        perAuthorLimit: perAuthorLimit,
        maxConcurrent: 10,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      for (final post in followingPosts) {
        merged.putIfAbsent(post.docID, () => post);
      }
    }

    final publicScheduled = await _fetchVisiblePublicIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit < 20 ? 20 : limit,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    for (final post in publicScheduled) {
      merged.putIfAbsent(post.docID, () => post);
    }

    final visible = await filterVisiblePosts(
      merged.values.toList(growable: false),
      currentUserId: currentUserId,
      followingIds: followingIds,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
    );

    if (kDebugMode) {
      debugPrint(
        '[FeedSnapshot] uid=$currentUserId personalFallback own=${ownPosts.length} '
        'followingSeed=${followingIds.length} '
        'merged=${merged.length} visible=${visible.length}',
      );
    }

    return FeedSourcePage(
      items: visible,
      lastDoc: null,
      usesPrimaryFeed: false,
    );
  }

  Future<bool> _tryRepairHybridFeed({
    required String userId,
    required int limit,
  }) async {
    if (IntegrationTestMode.skipBackgroundStartupWork) {
      return false;
    }
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return false;
    if (FeedSnapshotRepository._hybridBackfillRequested.contains(
      normalizedUserId,
    )) {
      return false;
    }
    FeedSnapshotRepository._hybridBackfillRequested.add(normalizedUserId);
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('backfillHybridFeedForUser');
      final response = await callable.call(<String, dynamic>{
        'uid': normalizedUserId,
        'perAuthorLimit': limit < 20 ? 3 : 4,
      });
      if (kDebugMode) {
        debugPrint(
          '[FeedSnapshot] uid=$normalizedUserId repairTriggered result=${response.data}',
        );
      }
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[FeedSnapshot] uid=$normalizedUserId repairFailed error=$error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      return false;
    }
  }

  Future<List<PostsModel>> _fetchHomeSnapshot(
    FeedSnapshotQuery query,
  ) async {
    final userId = query.userId.trim();
    if (userId.isEmpty) return const <PostsModel>[];
    final followingIds = await _loadFollowingIds(userId);
    final page = await fetchHomePage(
      userId: userId,
      followingIds: followingIds,
      hiddenPostIds: const <String>{},
      nowMs: DateTime.now().millisecondsSinceEpoch,
      cutoffMs: 0,
      limit: query.limit,
      preferCache: true,
      cacheOnly: false,
      usePrimaryFeedPaging: true,
    );
    return page.items;
  }

  Future<List<PostsModel>?> _loadWarmHomeSnapshot(
    FeedSnapshotQuery query,
  ) async {
    final posts = await _warmLaunchPool.loadPosts(
      IndexPoolKind.feed,
      limit: query.limit,
      allowStale: true,
    );
    if (posts.isEmpty) return null;
    final visible = await filterVisiblePosts(
      posts,
      currentUserId: query.userId.trim(),
      followingIds: await _loadFollowingIds(query.userId),
      hiddenPostIds: const <String>{},
      nowMs: DateTime.now().millisecondsSinceEpoch,
      cutoffMs: 0,
      limit: query.limit,
    );
    return visible.isEmpty ? null : visible;
  }

  Future<Set<String>> _loadFollowingIds(String userId) async {
    return VisibilityPolicyService.ensure().loadViewerFollowingIds(
      viewerUserId: userId,
      preferCache: true,
    );
  }

  Future<List<PostsModel>> _fetchVisiblePublicIzBirakPosts({
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final posts = await _postRepository.fetchPublicScheduledIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    if (posts.isEmpty) return const <PostsModel>[];
    final authorMeta = await _userSummaryResolver.resolveMany(
      posts.map((post) => post.userID).toSet().toList(growable: false),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    return posts.where((post) {
      final meta = authorMeta[post.userID];
      if (meta == null) return false;
      final rozet = meta.rozet.trim();
      return rozet.isNotEmpty || meta.isApproved;
    }).toList(growable: false);
  }

  Future<FeedSourcePage> _loadLegacyPage({
    required String currentUserId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required DocumentSnapshot<Map<String, dynamic>>? startAfter,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final page = await _postRepository.fetchAgendaWindowPage(
      cutoffMs: cutoffMs,
      nowMs: nowMs,
      limit: limit,
      startAfter: startAfter,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final visible = await filterVisiblePosts(
      page.items,
      currentUserId: currentUserId,
      followingIds: followingIds,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
    );
    return FeedSourcePage(
      items: visible,
      lastDoc: page.lastDoc,
      usesPrimaryFeed: false,
    );
  }

  Future<Map<String, Map<String, dynamic>>> _buildUserMeta(
    List<PostsModel> posts,
  ) async {
    final userIds =
        posts.map((post) => post.userID).where((id) => id.isNotEmpty);
    final summaries = await _userSummaryResolver.resolveMany(
      userIds.toSet().toList(growable: false),
      preferCache: true,
    );
    return summaries.map(
      (key, value) => MapEntry(key, value.toMap()),
    );
  }
}
