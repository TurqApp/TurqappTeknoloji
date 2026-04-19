part of 'feed_snapshot_repository.dart';

extension FeedSnapshotRepositoryFetchPart on FeedSnapshotRepository {
  static const Duration _feedLaunchCursorStep = Duration(minutes: 30);
  static const int _feedLaunchCursorWindowCount = 48;
  static const int _feedLaunchMotorTopUpMaxRounds = 2;

  int _feedHomeCutoffMs(int nowMs) =>
      nowMs - const Duration(days: 7).inMilliseconds;

  String _formatFeedMotorSampleWithMinute(
    Iterable<PostsModel> posts,
  ) {
    return posts.take(5).map((post) {
      final minuteOfHour =
          DateTime.fromMillisecondsSinceEpoch(post.timeStamp.toInt()).minute;
      return '${post.docID}:m$minuteOfHour';
    }).join(',');
  }

  Future<T> _profileFeedSnapshotStep<T>(
    String label,
    Future<T> Function() action,
  ) async {
    final startedAt = DateTime.now();
    debugPrint('[FeedSnapshotStep] start:$label');
    try {
      final result = await action();
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint('[FeedSnapshotStep] end:$label elapsedMs=$elapsedMs');
      return result;
    } catch (error) {
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint(
        '[FeedSnapshotStep] fail:$label elapsedMs=$elapsedMs error=$error',
      );
      rethrow;
    }
  }

  void _logFeedLaunchMotorInputSnapshot(
    List<PostsModel> visiblePosts, {
    required int limit,
    required DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    if (!_shouldLogDiagnostics || visiblePosts.isEmpty || startAfter != null) {
      return;
    }
    final anchorMs = startupSurfaceSessionSeed(sessionNamespace: 'feed');
    final snapshot = LaunchMotorSelectionService.analyzePool(
      latestPool: visiblePosts,
      anchorMs: anchorMs,
      window: feedLaunchMotorContract.window,
      bandMinutes: feedLaunchMotorContract.bandMinutes,
      subsliceMs: feedLaunchMotorContract.subsliceMs,
      minuteSets: feedLaunchMotorContract.minuteSets,
    );
    debugPrint(
      '[FeedLaunchMotorInput] '
      'anchor=${DateTime.fromMillisecondsSinceEpoch(anchorMs).toIso8601String()} '
      'motor=${snapshot.motorIndex} ownedMinutes=${snapshot.ownedMinutes.join(",")} '
      'visibleCount=${visiblePosts.length} strictCount=${snapshot.strictSelection.length} '
      'queueCount=${snapshot.queueCount} limit=$limit '
      'sample=${_formatFeedMotorSampleWithMinute(snapshot.strictSelection)}',
    );
  }

  Future<
      ({
        List<PostsModel> items,
        DocumentSnapshot<Map<String, dynamic>>? lastDoc,
      })> _topUpFeedLaunchMotorInputPool({
    required List<PostsModel> visiblePosts,
    required String userId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    if (visiblePosts.isEmpty || limit <= 0) {
      return (
        items: visiblePosts,
        lastDoc: lastDoc,
      );
    }
    final anchorMs = startupSurfaceSessionSeed(sessionNamespace: 'feed');
    final mergedVisibleById = <String, PostsModel>{
      for (final post in visiblePosts)
        if (post.docID.trim().isNotEmpty) post.docID.trim(): post,
    };
    var cursor = lastDoc;
    var selection = LaunchMotorSelectionService.buildPoolFillResult(
      latestPool: mergedVisibleById.values.toList(growable: false),
      anchorMs: anchorMs,
      contract: feedLaunchMotorContract,
      targetCount: limit,
    );
    var round = 0;

    while (selection.needsTopUp(limit) &&
        cursor != null &&
        !cacheOnly &&
        round < _feedLaunchMotorTopUpMaxRounds) {
      round += 1;
      final extraPage = await _postRepository.fetchRecentGlobalPostsPage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        maxTimeExclusive: _resolveFeedPageMaxTime(cursor),
        startAfter: cursor,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      cursor = extraPage.lastDoc;
      if (extraPage.items.isEmpty) {
        break;
      }
      final extraPrimaryPosts = await _resolveVisibleDiscoveryPublicPosts(
        extraPage.items,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      if (extraPrimaryPosts.isEmpty) {
        continue;
      }
      final extraVisible = await filterVisiblePosts(
        _sortFeedCandidatesForVisibility(extraPrimaryPosts),
        currentUserId: userId,
        followingIds: followingIds,
        hiddenPostIds: hiddenPostIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        summaryCacheOnly: cacheOnly,
        refreshNonPublicCachedSummaries: !cacheOnly,
      );
      for (final post in extraVisible) {
        final docId = post.docID.trim();
        if (docId.isEmpty) continue;
        mergedVisibleById.putIfAbsent(docId, () => post);
      }
      selection = LaunchMotorSelectionService.buildPoolFillResult(
        latestPool: mergedVisibleById.values.toList(growable: false),
        anchorMs: anchorMs,
        contract: feedLaunchMotorContract,
        targetCount: limit,
      );
      if (_shouldLogDiagnostics) {
        debugPrint(
          '[FeedLaunchMotorInput] '
          'status=topup round=$round strictCount=${selection.strictCount} '
          'target=$limit candidateCount=${mergedVisibleById.length}',
        );
      }
    }

    return (
      items: selection.selectedPool,
      lastDoc: cursor ?? lastDoc,
    );
  }

  Future<Map<String, PostsModel>> _rehydrateHomeFeedVideoCards(
    Map<String, PostsModel> postsById, {
    required bool cacheOnly,
  }) async {
    if (cacheOnly || postsById.isEmpty) return postsById;
    final videoIds = postsById.values
        .where((post) => post.hasVideoSignal)
        .map((post) => post.docID)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (videoIds.isEmpty) return postsById;

    final canonicalById = await _postRepository.fetchPostsByIds(
      videoIds,
      preferCache: false,
      cacheOnly: false,
    );
    if (canonicalById.isEmpty) return postsById;

    final merged = Map<String, PostsModel>.from(postsById);
    for (final docId in videoIds) {
      final current = postsById[docId];
      final canonical = canonicalById[docId];
      if (current == null || canonical == null) continue;
      merged[docId] = current.copyWith(
        aspectRatio: canonical.aspectRatio,
        deletedPost: canonical.deletedPost,
        flood: canonical.flood,
        floodCount: canonical.floodCount,
        gizlendi: canonical.gizlendi,
        img: canonical.img,
        isUploading: canonical.isUploading,
        mainFlood: canonical.mainFlood,
        thumbnail: canonical.thumbnail,
        video: canonical.video,
        hlsMasterUrl: canonical.hlsMasterUrl,
        hlsStatus: canonical.hlsStatus,
        hlsUpdatedAt: canonical.hlsUpdatedAt,
      );
    }
    return merged;
  }

  int? _asNullableFeedInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Future<List<PostsModel>> loadQuickCachedPersonalFallback({
    required String userId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int limit,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return const <PostsModel>[];
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final page = await _loadPersonalFallbackPage(
      currentUserId: normalizedUserId,
      followingIds: followingIds,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: _feedHomeCutoffMs(nowMs),
      limit: limit,
      preferCache: true,
      cacheOnly: true,
    );
    return page.items;
  }

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
    bool refreshNonPublicCachedSummaries = true,
    bool includeSupplementalSources = true,
    bool bypassInitialPrimaryCursorShift = false,
    FeedPrimarySourceMode? primarySourceOverride,
    int? typesensePage,
  }) async {
    const contract = FeedSnapshotRepository._homeContract;
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

    final primarySourceMode = _resolveFeedPrimarySourceMode(
      startAfter: startAfter,
      override: primarySourceOverride,
      typesensePage: typesensePage,
    );
    if (_shouldLogDiagnostics) {
      debugPrint(
        '[FeedSnapshotSource] uid=$normalizedUserId startAfter=${startAfter?.id ?? ""} '
        'source=${primarySourceMode.name}',
      );
    }
    if (primarySourceMode == FeedPrimarySourceMode.typesense) {
      return _profileFeedSnapshotStep('fetch_typesense_primary_only', () {
        return _loadTypesensePrimaryOnlyPage(
          currentUserId: normalizedUserId,
          followingIds: followingIds,
          hiddenPostIds: hiddenPostIds,
          nowMs: nowMs,
          cutoffMs: cutoffMs,
          limit: limit,
          page: typesensePage ?? 1,
        );
      });
    }

    final initialPrimaryMaxTimeExclusive = startAfter == null
        ? (bypassInitialPrimaryCursorShift
            ? nowMs + 1
            : _resolveInitialPrimaryWindowMaxTime(
                nowMs: nowMs,
                cutoffMs: cutoffMs,
              ))
        : _resolveFeedPageMaxTime(startAfter);

    final primaryPage =
        await _profileFeedSnapshotStep('fetch_global_primary', () {
      return _postRepository.fetchRecentGlobalPostsPage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        maxTimeExclusive: initialPrimaryMaxTimeExclusive,
        startAfter: startAfter,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
    });

    final primaryPosts =
        await _profileFeedSnapshotStep('resolve_global_primary', () {
      return _resolveVisibleDiscoveryPublicPosts(
        primaryPage.items,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
    });

    if (_shouldLogDiagnostics) {
      debugPrint(
        '[FeedSnapshot] uid=$normalizedUserId startAfter=${startAfter?.id ?? ''} '
        'primary=${primaryPage.items.length} visiblePrimary=${primaryPosts.length} limit=$limit '
        'contract=${contract.contractId}',
      );
    }

    final merged = <String, PostsModel>{};
    for (final post in primaryPosts) {
      merged[post.docID] = post;
    }

    final primarySatisfiesPage = primaryPosts.length >= limit;

    const List<PostsModel> followingPosts = <PostsModel>[];

    const List<String> celebIds = <String>[];

    const List<PostsModel> publicScheduled = <PostsModel>[];
    for (final post in publicScheduled) {
      merged.putIfAbsent(post.docID, () => post);
    }

    final globalBadgePosts = includeSupplementalSources && !primarySatisfiesPage
        ? await _profileFeedSnapshotStep('fetch_global_badge', () {
            return _fetchVisibleGlobalBadgePosts(
              nowMs: nowMs,
              cutoffMs: cutoffMs,
              limit: limit < ReadBudgetRegistry.feedGlobalBadgeMinLimit
                  ? ReadBudgetRegistry.feedGlobalBadgeMinLimit
                  : limit,
              maxTimeExclusive: initialPrimaryMaxTimeExclusive,
              preferCache: preferCache,
              cacheOnly: cacheOnly,
            );
          })
        : const <PostsModel>[];
    for (final post in globalBadgePosts) {
      merged.putIfAbsent(post.docID, () => post);
    }

    if (_shouldLogDiagnostics) {
      debugPrint(
        '[FeedSnapshot] uid=$normalizedUserId merged=${merged.length} '
        'following=${followingPosts.length} celebAuthors=${celebIds.length} '
        'publicScheduled=${publicScheduled.length} globalBadge=${globalBadgePosts.length}',
      );
    }

    if (merged.isEmpty && primaryPage.lastDoc == null && startAfter == null) {
      if (_shouldLogDiagnostics) {
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
        refreshNonPublicCachedSummaries: refreshNonPublicCachedSummaries,
      );
      if (personalFallback.items.isNotEmpty) {
        return personalFallback;
      }
      if (_shouldLogDiagnostics) {
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

    final visible = await _profileFeedSnapshotStep('filter_visible', () {
      return filterVisiblePosts(
        _sortFeedCandidatesForVisibility(
          merged.values.toList(growable: false),
        ),
        currentUserId: normalizedUserId,
        followingIds: followingIds,
        hiddenPostIds: hiddenPostIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        summaryCacheOnly: cacheOnly,
        refreshNonPublicCachedSummaries: refreshNonPublicCachedSummaries,
      );
    });

    if (_shouldLogDiagnostics) {
      debugPrint(
        '[FeedSnapshot] uid=$normalizedUserId visible=${visible.length} '
        'sample=${visible.take(5).map((post) => post.docID).join(',')}',
      );
    }
    final toppedUpInput = await _topUpFeedLaunchMotorInputPool(
      visiblePosts: visible,
      userId: normalizedUserId,
      followingIds: followingIds,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      lastDoc: primaryPage.lastDoc,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final launchMotorInputItems = toppedUpInput.items;
    _logFeedLaunchMotorInputSnapshot(
      launchMotorInputItems,
      limit: limit,
      startAfter: startAfter,
    );

    if (launchMotorInputItems.isEmpty && startAfter == null) {
      if (_shouldLogDiagnostics) {
        debugPrint(
          '[FeedSnapshot] uid=$normalizedUserId fallback=personal '
          'reason=visible_empty primary=${primaryPosts.length} merged=${merged.length}',
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
        refreshNonPublicCachedSummaries: refreshNonPublicCachedSummaries,
      );
      if (personalFallback.items.isNotEmpty) {
        return personalFallback;
      }
      if (_shouldLogDiagnostics) {
        debugPrint(
          '[FeedSnapshot] uid=$normalizedUserId fallback=legacy '
          'reason=visible_empty_personal_empty primary=${primaryPosts.length} '
          'merged=${merged.length}',
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

    _invariantGuard.assertNotEmptyAfterRefresh(
      surface: 'feed',
      invariantKey: 'snapshot_visible_after_filter',
      hadSnapshot: merged.isNotEmpty,
      previousCount: merged.length,
      nextCount: visible.length,
      payload: <String, dynamic>{
        'uid': normalizedUserId,
        'primaryCount': primaryPosts.length,
        'usesPrimaryFeed': true,
        'feedContract': contract.contractId,
      },
    );

    return FeedSourcePage(
      items: launchMotorInputItems,
      lastDoc: toppedUpInput.lastDoc,
      usesPrimaryFeed: true,
      itemsPreplanned: true,
      nextTypesensePage: null,
    );
  }

  FeedPrimarySourceMode _resolveFeedPrimarySourceMode({
    required DocumentSnapshot<Map<String, dynamic>>? startAfter,
    FeedPrimarySourceMode? override,
    int? typesensePage,
  }) {
    return FeedSnapshotRepository.resolvePrimarySourceMode(
      startAfter: startAfter,
      override: override,
      typesensePage: typesensePage,
    );
  }

  Future<FeedSourcePage> _loadTypesensePrimaryOnlyPage({
    required String currentUserId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required int page,
  }) async {
    final anchorMs = startupSurfaceSessionSeed(sessionNamespace: 'feed');
    final ownedMinutes = LaunchMotorSelectionService.resolveOwnedMinutes(
      anchorMs: anchorMs,
      bandMinutes: feedLaunchMotorContract.bandMinutes,
      minuteSets: feedLaunchMotorContract.minuteSets,
    );
    final candidateLimit = FeedTypesensePolicy.resolveCandidateLimit(limit);
    final motorPage = await _postRepository.fetchTypesenseMotorCandidates(
      surface: 'feed',
      ownedMinutes: ownedMinutes,
      limit: candidateLimit,
      page: page,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
    );
    if (_shouldLogDiagnostics) {
      debugPrint(
        '[FeedSnapshotTypesense] uid=$currentUserId '
        'ownedMinutes=${motorPage.ownedMinutes.join(",")} '
        'raw=${motorPage.items.length} found=${motorPage.found} '
        'outOf=${motorPage.outOf} searchTimeMs=${motorPage.searchTimeMs} '
        'requestedLimit=$limit candidateLimit=$candidateLimit',
      );
    }
    if (motorPage.items.isEmpty) {
      return FeedSourcePage(
        items: const <PostsModel>[],
        lastDoc: null,
        usesPrimaryFeed: true,
        itemsPreplanned: true,
        nextTypesensePage: null,
      );
    }

    final visible = await filterVisiblePosts(
      _sortFeedCandidatesForVisibility(motorPage.items),
      currentUserId: currentUserId,
      followingIds: followingIds,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      summaryCacheOnly: false,
      refreshNonPublicCachedSummaries: false,
      progressiveSummaryResolution: true,
    );
    final selection = LaunchMotorSelectionService.buildPoolFillResult(
      latestPool: visible,
      anchorMs: anchorMs,
      contract: feedLaunchMotorContract,
      targetCount: limit,
    );
    final selectedItems = selection.selectedPool;
    _logFeedLaunchMotorInputSnapshot(
      selectedItems,
      limit: limit,
      startAfter: null,
    );
    if (_shouldLogDiagnostics) {
      debugPrint(
        '[FeedSnapshotTypesense] uid=$currentUserId '
        'visible=${visible.length} selected=${selectedItems.length} '
        'strictCount=${selection.strictCount}',
      );
    }
    final nextTypesensePage =
        FeedTypesensePagingContract.resolveNextTypesensePage(
      itemCount: motorPage.items.length,
      limit: candidateLimit,
      page: motorPage.page,
      found: motorPage.found,
    );
    return FeedSourcePage(
      items: selectedItems,
      lastDoc: null,
      usesPrimaryFeed: true,
      itemsPreplanned: true,
      nextTypesensePage: nextTypesensePage,
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
    bool refreshNonPublicCachedSummaries = true,
  }) async {
    if (currentUserId.isEmpty) {
      return const FeedSourcePage(
        items: <PostsModel>[],
        lastDoc: null,
        usesPrimaryFeed: false,
        itemsPreplanned: false,
        nextTypesensePage: null,
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

    final globalBadgePosts = await _fetchVisibleGlobalBadgePosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit < ReadBudgetRegistry.feedGlobalBadgeMinLimit
          ? ReadBudgetRegistry.feedGlobalBadgeMinLimit
          : limit,
      maxTimeExclusive: null,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    for (final post in globalBadgePosts) {
      merged.putIfAbsent(post.docID, () => post);
    }

    final visible = await filterVisiblePosts(
      _sortFeedCandidatesForVisibility(
        merged.values.toList(growable: false),
      ),
      currentUserId: currentUserId,
      followingIds: followingIds,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      summaryCacheOnly: cacheOnly,
      refreshNonPublicCachedSummaries: refreshNonPublicCachedSummaries,
    );

    if (_shouldLogDiagnostics) {
      debugPrint(
        '[FeedSnapshot] uid=$currentUserId personalFallback own=${ownPosts.length} '
        'merged=${merged.length} visible=${visible.length} '
        'globalBadge=${globalBadgePosts.length}',
      );
    }

    return FeedSourcePage(
      items: visible,
      lastDoc: null,
      usesPrimaryFeed: false,
      itemsPreplanned: false,
      nextTypesensePage: null,
    );
  }

  List<PostsModel> _sortFeedCandidatesForVisibility(List<PostsModel> posts) {
    if (posts.length < 2) return posts;
    final sorted = posts.toList(growable: false)
      ..sort((left, right) {
        final timeCompare = right.timeStamp.compareTo(left.timeStamp);
        if (timeCompare != 0) {
          return timeCompare;
        }
        return left.docID.trim().compareTo(right.docID.trim());
      });
    return sorted;
  }

  Future<List<PostsModel>> _fetchHomeSnapshot(
    FeedSnapshotQuery query,
  ) async {
    final userId = query.userId.trim();
    if (userId.isEmpty) return const <PostsModel>[];
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final followingIds = await _loadFollowingIds(userId);
    final page = await fetchHomePage(
      userId: userId,
      followingIds: followingIds,
      hiddenPostIds: const <String>{},
      nowMs: nowMs,
      cutoffMs: _feedHomeCutoffMs(nowMs),
      limit: query.effectiveLimit,
      preferCache: true,
      cacheOnly: false,
      usePrimaryFeedPaging: true,
      refreshNonPublicCachedSummaries: false,
    );
    return page.items;
  }

  Future<List<PostsModel>?> _loadWarmHomeSnapshot(
    FeedSnapshotQuery query,
  ) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final posts = await _warmLaunchPool.loadPosts(
      IndexPoolKind.feed,
      limit: query.effectiveLimit,
      allowStale: true,
    );
    if (posts.isEmpty) return null;
    final visible = await filterVisiblePosts(
      posts,
      currentUserId: query.userId.trim(),
      followingIds: await _loadFollowingIds(query.userId),
      hiddenPostIds: const <String>{},
      nowMs: nowMs,
      cutoffMs: _feedHomeCutoffMs(nowMs),
      limit: query.effectiveLimit,
      summaryCacheOnly: true,
      refreshNonPublicCachedSummaries: false,
    );
    if (visible.isEmpty) return null;

    // Warm-launch bootstrap must stay local-only; live video rehydrate here
    // delays the first feed paint and defeats the point of startup cache.
    final rehydratedById = await _rehydrateHomeFeedVideoCards(
      <String, PostsModel>{
        for (final post in visible) post.docID: post,
      },
      cacheOnly: true,
    );
    return visible
        .map((post) => rehydratedById[post.docID] ?? post)
        .toList(growable: false);
  }

  Future<Set<String>> _loadFollowingIds(String userId) async {
    return VisibilityPolicyService.ensure().loadViewerFollowingIds(
      viewerUserId: userId,
      preferCache: true,
    );
  }

  int? _resolveFeedPageMaxTime(
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  ) {
    if (startAfter == null) return null;
    final data = startAfter.data();
    return _asNullableFeedInt(data?['timeStamp']);
  }

  int _resolveInitialPrimaryWindowMaxTime({
    required int nowMs,
    required int cutoffMs,
  }) {
    final launchBucket = startupVariantIndexForSurface(
      surfaceKey: 'feed_launch_cursor',
      sessionNamespace: 'feed',
      variantCount: _feedLaunchCursorWindowCount,
    );
    final shiftedNow =
        nowMs - (_feedLaunchCursorStep.inMilliseconds * launchBucket);
    final floor = cutoffMs + 1;
    if (shiftedNow < floor) {
      return floor;
    }
    return shiftedNow;
  }

  Future<List<PostsModel>> _fetchVisibleGlobalBadgePosts({
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required int? maxTimeExclusive,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final posts = await _postRepository.fetchRecentGlobalPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      maxTimeExclusive: maxTimeExclusive,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    return _resolveVisibleDiscoveryPublicPosts(
      posts,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
      limit: limit,
    );
  }

  Future<List<PostsModel>> _resolveVisibleDiscoveryPublicPosts(
    List<PostsModel> posts, {
    required bool preferCache,
    required bool cacheOnly,
    int? limit,
  }) async {
    if (posts.isEmpty) return const <PostsModel>[];

    final authorMeta = await _userSummaryResolver.resolveMany(
      posts.map((post) => post.userID).toSet().toList(growable: false),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final visible = <PostsModel>[];
    for (final post in posts) {
      final meta = authorMeta[post.userID];
      if (meta == null || meta.isDeleted) continue;
      if (!isDiscoveryPublicAuthor(
        rozet: meta.rozet,
        isApproved: meta.isApproved,
      )) {
        continue;
      }
      visible.add(
        post.copyWith(
          authorNickname: post.authorNickname.isNotEmpty
              ? post.authorNickname
              : meta.nickname,
          authorDisplayName: post.authorDisplayName.isNotEmpty
              ? post.authorDisplayName
              : meta.displayName,
          authorAvatarUrl: post.authorAvatarUrl.isNotEmpty
              ? post.authorAvatarUrl
              : meta.avatarUrl,
          rozet: post.rozet.isNotEmpty ? post.rozet : meta.rozet,
        ),
      );
      if (limit != null && visible.length >= limit) {
        break;
      }
    }
    return visible;
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
      summaryCacheOnly: cacheOnly,
    );
    return FeedSourcePage(
      items: visible,
      lastDoc: page.lastDoc,
      usesPrimaryFeed: false,
      itemsPreplanned: false,
      nextTypesensePage: null,
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
