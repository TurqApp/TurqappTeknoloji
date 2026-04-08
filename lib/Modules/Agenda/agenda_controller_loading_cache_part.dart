part of 'agenda_controller.dart';

extension AgendaControllerLoadingCachePart on AgendaController {
  Future<T> _profileFeedStartupCacheStep<T>(
    String label,
    Future<T> Function() action,
  ) async {
    final startedAt = DateTime.now();
    debugPrint('[FeedStartupCache] start:$label');
    try {
      final result = await action();
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint('[FeedStartupCache] end:$label elapsedMs=$elapsedMs');
      return result;
    } catch (error) {
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint(
        '[FeedStartupCache] fail:$label elapsedMs=$elapsedMs error=$error',
      );
      rethrow;
    }
  }

  Future<List<PostsModel>> _hydrateStartupAuthorIdentityFromCache(
    List<PostsModel> posts,
  ) async {
    if (posts.isEmpty) return const <PostsModel>[];
    final authorIds = posts
        .map((post) => post.userID.trim())
        .where((uid) => uid.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (authorIds.isEmpty) return posts;

    var summaries = const <String, dynamic>{};
    try {
      summaries = await _userSummaryResolver.resolveMany(
        authorIds,
        preferCache: true,
        cacheOnly: true,
      );
    } catch (_) {}

    final unresolvedIds = authorIds.where((uid) {
      final summary = summaries[uid];
      return summary == null || summary.avatarUrl.trim().isEmpty;
    }).toList(growable: false);
    final cachedProfiles = <String, Map<String, dynamic>>{};
    if (unresolvedIds.isNotEmpty) {
      try {
        cachedProfiles.addAll(
          await _profileCache.getProfiles(
            unresolvedIds,
            preferCache: true,
            cacheOnly: true,
          ),
        );
      } catch (_) {}
    }
    if (summaries.isEmpty && cachedProfiles.isEmpty) return posts;

    return posts.map((post) {
      final summary = summaries[post.userID.trim()];
      final profile = cachedProfiles[post.userID.trim()];
      final profileNickname = (profile?['nickname'] ?? '').toString().trim();
      final profileDisplayName =
          (profile?['displayName'] ?? '').toString().trim();
      final profileAvatarUrl = CdnUrlBuilder.toCdnUrl(
        (profile?['avatarUrl'] ?? '').toString().trim(),
      );
      final profileRozet = (profile?['rozet'] ?? '').toString().trim();
      final summaryNickname = summary?.nickname.trim() ?? '';
      final summaryDisplayName = summary?.displayName.trim() ?? '';
      final summaryAvatarUrl =
          CdnUrlBuilder.toCdnUrl(summary?.avatarUrl.trim() ?? '');
      final summaryRozet = summary?.rozet.trim() ?? '';
      if (summary == null && profile == null) return post;
      return post.copyWith(
        authorNickname: post.authorNickname.trim().isNotEmpty
            ? post.authorNickname
            : (summaryNickname.isNotEmpty ? summaryNickname : profileNickname),
        authorDisplayName: post.authorDisplayName.trim().isNotEmpty
            ? post.authorDisplayName
            : (summaryDisplayName.isNotEmpty
                ? summaryDisplayName
                : profileDisplayName),
        authorAvatarUrl: post.authorAvatarUrl.trim().isNotEmpty
            ? post.authorAvatarUrl
            : (summaryAvatarUrl.isNotEmpty
                ? summaryAvatarUrl
                : profileAvatarUrl),
        rozet: post.rozet.trim().isNotEmpty
            ? post.rozet
            : (summaryRozet.isNotEmpty ? summaryRozet : profileRozet),
      );
    }).toList(growable: false);
  }

  Future<void> _primeStartupAvatarHints(Iterable<PostsModel> posts) async {
    final urls = <String>[];
    final seen = <String>{};
    for (final post in posts) {
      final url = CdnUrlBuilder.toCdnUrl(post.authorAvatarUrl.trim());
      if (url.isEmpty || !seen.add(url)) continue;
      urls.add(url);
      if (urls.length >= 12) break;
    }
    if (urls.isEmpty) return;

    Future<void> primeUrl(
      String url, {
      required bool allowNetwork,
    }) async {
      try {
        final remembered =
            TurqImageCacheManager.rememberedResolvedFilePathForUrl(url);
        if (remembered.isNotEmpty) return;
        final cached = await TurqImageCacheManager.instance.getFileFromCache(
          url,
        );
        var path = cached?.file.path ?? '';
        if (path.isEmpty && allowNetwork) {
          final file = await TurqImageCacheManager.warmUrl(url).timeout(
            const Duration(milliseconds: 220),
            onTimeout: () => throw TimeoutException('avatar_warm_timeout'),
          );
          path = file.path;
        }
        if (path.isEmpty) return;
        TurqImageCacheManager.rememberResolvedFile(url, path);
      } catch (_) {}
    }

    final criticalCount = ContentPolicy.isOnWiFi ? 4 : 0;
    final criticalUrls = urls.take(criticalCount).toList(growable: false);
    final nonCriticalUrls = urls.skip(criticalCount).toList(growable: false);

    if (criticalUrls.isNotEmpty) {
      await Future.wait(
        criticalUrls.map(
          (url) => primeUrl(
            url,
            allowNetwork: true,
          ),
        ),
      );
    }
    for (final url in nonCriticalUrls) {
      await primeUrl(
        url,
        allowNetwork: false,
      );
    }
  }

  int _startupSeedLoadLimit(int targetCount) {
    if (targetCount <= 0) return 0;
    return 210;
  }

  int _startupShardCandidateLimit(int targetCount) {
    if (targetCount <= 0) return 0;
    return min(_startupSeedLoadLimit(targetCount), 90);
  }

  bool _hasStartupVariationRoom(
    Iterable<PostsModel> candidates, {
    required int targetCount,
  }) {
    if (targetCount <= 0) return false;
    var count = 0;
    for (final _ in candidates) {
      count++;
      if (count > targetCount) {
        return true;
      }
    }
    return false;
  }

  int _startupWarmSnapshotMinimumQuickFillCount(int targetCount) {
    if (targetCount <= 0) return 0;
    final toleratedMissing = max(1, targetCount ~/ 10);
    final minimumCount = targetCount - toleratedMissing;
    return minimumCount < ReadBudgetRegistry.feedBufferedFetchLimit
        ? ReadBudgetRegistry.feedBufferedFetchLimit
        : minimumCount;
  }

  void _scheduleStartupQuickFillFollowUps(
    List<PostsModel> shown, {
    bool includeReshareFetch = false,
  }) {
    if (shown.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed || shown.isEmpty) return;
      _scheduleInitialFeedVideoPosterWarmup(shown);
      unawaited(_revalidateQuickFilledAgenda(shown));
      if (includeReshareFetch) {
        _scheduleReshareFetchForPosts(shown, perPostLimit: 1);
      }
    });
  }

  void _scheduleStartupAvatarHintPrime(
    List<PostsModel> posts, {
    required String source,
  }) {
    if (posts.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed || posts.isEmpty) return;
      unawaited(
        _profileFeedStartupCacheStep(
          source,
          () => _primeStartupAvatarHints(posts),
        ),
      );
    });
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

  List<PostsModel> _composeStartupFeedItems({
    required List<PostsModel> cacheCandidates,
    List<PostsModel> liveCandidates = const <PostsModel>[],
    required int targetCount,
    bool allowSparseSlotFallback = false,
  }) {
    if ((cacheCandidates.isEmpty && liveCandidates.isEmpty) ||
        targetCount <= 0) {
      _startupCacheOriginVideoDocIds.clear();
      return const <PostsModel>[];
    }
    _startupPresentationApplied = true;
    final startupVariant = _feedStartupVariantOverride();
    final cacheReadyVideoDocIds = _startupCacheReadyVideoDocIds(<PostsModel>[
      ...cacheCandidates,
      ...liveCandidates,
    ]);
    final shownItems = _agendaFeedApplicationService.composeStartupFeedItems(
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
    FeedDiversityMemoryService.ensure().rememberStartupHead(shownItems);
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
    return _agendaFeedApplicationService.startupSupportTargetsForCount(
      targetCount,
    );
  }

  int _startupSupportFallbackCutoffMs(int nowMs) =>
      nowMs - const Duration(days: 30).inMilliseconds;

  int _startupFloodSupportFetchLimit(int targetCount) {
    final normalizedTarget = targetCount < 1 ? 1 : targetCount;
    return max(normalizedTarget * 3, 120);
  }

  String? _startupSupportKind(PostsModel post) {
    if (post.isFloodSeriesRoot && post.floodCount.toInt() > 1) return 'flood';
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
    if (targetCount < ReadBudgetRegistry.feedBufferedFetchLimit) {
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

  bool _startupWarmSnapshotCoverageSatisfied(
    Map<String, int> deficits,
  ) {
    if (deficits.isEmpty) return true;
    final blockingKeys = deficits.keys.where((key) => key != 'text');
    return blockingKeys.isEmpty;
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
  }) async {
    final monthCutoffMs = _startupSupportFallbackCutoffMs(nowMs);
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
      if (ts < monthCutoffMs) {
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
      cutoffMs: monthCutoffMs,
      limit: fallbackLimit,
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
      if (ts < monthCutoffMs) continue;
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

  List<PostsModel> _mergeStartupHeadWithCurrentItems({
    required List<PostsModel> currentItems,
    required List<PostsModel> liveItems,
    required int targetCount,
    required int nowMs,
    int? startupVariantOverride,
  }) {
    final shownItems =
        _agendaFeedApplicationService.mergeStartupHeadWithCurrentItems(
      currentItems: currentItems,
      liveItems: liveItems,
      targetCount: targetCount,
      nowMs: nowMs,
      startupVariantOverride:
          startupVariantOverride ?? _feedStartupVariantOverride(),
      cacheReadyVideoDocIds: _startupCacheReadyVideoDocIds(currentItems),
      preferLiveStartupHead: true,
    );
    _startupCacheOriginVideoDocIds
      ..clear()
      ..addAll(
        _startupCacheOriginVideoDocIdsForShownItems(
          shownItems: shownItems,
          cacheCandidates: currentItems,
          liveCandidates: liveItems,
        ),
      );
    return shownItems;
  }

  List<PostsModel> _applyStartupFeedPresentationOrder(
    List<PostsModel> posts,
  ) {
    if (_startupPresentationApplied || posts.length < 2) {
      return posts;
    }
    return _composeStartupFeedItems(
      cacheCandidates: posts,
      targetCount: min(
        posts.length,
        FeedSnapshotRepository.startupHomeLimitValue,
      ),
    );
  }

  void _reorderAgendaForStartupPresentationIfNeeded() {
    if (_startupPresentationApplied || agendaList.length < 2) {
      return;
    }
    agendaList.assignAll(
      _applyStartupFeedPresentationOrder(
        agendaList.toList(growable: false),
      ),
    );
  }

  Future<Set<String>> _loadStartupFollowingIds(
    String uid, {
    Duration timeout = const Duration(milliseconds: 180),
  }) async {
    var effectiveFollowingIds = followingIDs.toSet();
    if (effectiveFollowingIds.isNotEmpty || uid.isEmpty) {
      return effectiveFollowingIds;
    }
    try {
      final cachedFollowingIds = await _visibilityPolicy
          .loadViewerFollowingIds(
            viewerUserId: uid,
            preferCache: true,
          )
          .timeout(
            timeout,
            onTimeout: () => effectiveFollowingIds,
          );
      if (cachedFollowingIds.isNotEmpty) {
        effectiveFollowingIds = cachedFollowingIds;
        followingIDs.assignAll(cachedFollowingIds);
      }
    } catch (_) {}
    return effectiveFollowingIds;
  }

  Future<void> _tryQuickFillFromCache({int? limit}) async {
    if (agendaList.isEmpty && centeredIndex.value != -1) {
      centeredIndex.value = -1;
    }
    final effectiveLimit =
        limit ?? FeedSnapshotRepository.startupHomeLimitValue;
    await _tryQuickFillFromPool(limit: effectiveLimit);
    if (agendaList.isNotEmpty) return;
    if (ContentPolicy.isConnected) {
      debugPrint(
        '[FeedStartupCache] status=skip_connected_cache_seed_fill '
        'targetCount=$effectiveLimit',
      );
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = _agendaCutoffMs(nowMs);
    final seedLoadLimit = _startupSeedLoadLimit(effectiveLimit);
    final page = await _loadAgendaSourcePage(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: seedLoadLimit,
      useStoredCursor: false,
      preferCache: true,
      cacheOnly: true,
    );
    final startupCandidates = await _augmentStartupSupportCandidates(
      candidates: page.items,
      nowMs: nowMs,
      primaryCutoffMs: cutoffMs,
      targetCount: effectiveLimit,
      preferCache: true,
      cacheOnly: true,
      allowNetworkFallbackFetch: true,
    );
    final filtered = _composeStartupFeedItems(
      cacheCandidates: startupCandidates,
      targetCount: effectiveLimit,
    );
    if (filtered.isEmpty) return;
    final quickFilled = await _hydrateStartupAuthorIdentityFromCache(filtered);
    final existingIDs = agendaList.map((e) => e.docID).toSet();
    final toAdd =
        quickFilled.where((p) => !existingIDs.contains(p.docID)).toList();
    if (toAdd.isNotEmpty) {
      final shouldActivateStartupStages = agendaList.isEmpty;
      if (shouldActivateStartupStages) {
        _startupRenderBootstrapHold = true;
        _activateStartupRenderStages(
          reason: 'quick_fill_cache',
        );
      }
      _addUniqueToAgenda(toAdd);
      _reorderAgendaForStartupPresentationIfNeeded();
      if (_needsInitialFeedPlaybackPrime) {
        primeInitialCenteredPost();
      }
      _applyStartupRenderStagesNow();
      _scheduleBufferedFeedBlockPrefetchAfterFrame(
        reason: 'quick_fill_cache',
      );
      _scheduleStartupQuickFillFollowUps(
        toAdd,
        includeReshareFetch: true,
      );
      _scheduleStartupAvatarHintPrime(
        quickFilled,
        source: 'prime_avatar_hints_from_cache_deferred',
      );

      if (agendaList.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty &&
              (_needsInitialFeedPlaybackPrime || centeredIndex.value == -1)) {
            primeInitialCenteredPost();
          }
        });
      }
    }
  }

  Future<bool> _tryQuickFillFromPool({int? limit}) async {
    final me = CurrentUserService.instance.effectiveUserId;
    if (me.isEmpty) return false;
    final effectiveLimit =
        limit ?? FeedSnapshotRepository.startupHomeLimitValue;
    final startupShardLimit = _startupShardCandidateLimit(effectiveLimit);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final allowStartupShardQuickFill = !ContentPolicy.isConnected;
    final shardSeed = allowStartupShardQuickFill
        ? await _profileFeedStartupCacheStep(
            'inspect_startup_shard',
            () => _feedSnapshotRepository.inspectHomeStartupShard(
              userId: me,
              limit: startupShardLimit,
            ),
          )
        : const <PostsModel>[];
    if (!allowStartupShardQuickFill) {
      debugPrint(
        '[FeedStartupShard] status=skip_connected '
        'targetCount=$effectiveLimit',
      );
    }
    if (shardSeed.isNotEmpty) {
      debugPrint(
        '[FeedStartupShard] count=${shardSeed.length} '
        'sample=${shardSeed.take(5).map((post) => post.docID).join(',')}',
      );
      if (!_hasStartupVariationRoom(
        shardSeed,
        targetCount: effectiveLimit,
      )) {
        debugPrint(
          '[FeedStartupShard] status=skip_insufficient_variation '
          'count=${shardSeed.length} targetCount=$effectiveLimit',
        );
      } else {
        final startupCandidates = await _profileFeedStartupCacheStep(
          'augment_support_from_shard',
          () => _augmentStartupSupportCandidates(
            candidates: shardSeed,
            nowMs: nowMs,
            primaryCutoffMs: _agendaCutoffMs(nowMs),
            targetCount: effectiveLimit,
            preferCache: true,
            cacheOnly: true,
            allowNetworkFallbackFetch: true,
          ),
        );
        final quickFiltered = _composeStartupFeedItems(
          cacheCandidates: startupCandidates,
          targetCount: effectiveLimit,
        );
        if (quickFiltered.isNotEmpty) {
          final quickFilled = await _profileFeedStartupCacheStep(
            'hydrate_author_identity_from_shard',
            () => _hydrateStartupAuthorIdentityFromCache(quickFiltered),
          );
          _startupLiveHeadApplied = false;
          final shouldActivateStartupStages = agendaList.isEmpty;
          if (shouldActivateStartupStages) {
            _startupRenderBootstrapHold = true;
            _activateStartupRenderStages(
              reason: 'quick_fill_shard',
            );
          }
          _addUniqueToAgenda(quickFilled);
          _reorderAgendaForStartupPresentationIfNeeded();
          if (_needsInitialFeedPlaybackPrime) {
            primeInitialCenteredPost();
          }
          _applyStartupRenderStagesNow();
          _scheduleBufferedFeedBlockPrefetchAfterFrame(
            reason: 'quick_fill_shard',
          );
          _scheduleStartupQuickFillFollowUps(quickFilled);
          _scheduleStartupAvatarHintPrime(
            quickFilled,
            source: 'prime_avatar_hints_from_shard_deferred',
          );
          if (agendaList.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (agendaList.isNotEmpty &&
                  (_needsInitialFeedPlaybackPrime ||
                      centeredIndex.value == -1)) {
                primeInitialCenteredPost();
              }
            });
          }
          return true;
        }
      }
    }

    final seedLoadLimit = _startupSeedLoadLimit(effectiveLimit);
    final snapshot = await _profileFeedStartupCacheStep(
      'bootstrap_home_snapshot',
      () => _feedSnapshotRepository.bootstrapHome(
        userId: me,
        limit: seedLoadLimit,
      ),
    );
    final hadWarmSnapshot = snapshot.hasLocalSnapshot;
    final warmSeed = snapshot.data ?? const <PostsModel>[];
    if (warmSeed.isEmpty) return hadWarmSnapshot;
    if (ContentPolicy.isConnected && snapshot.isStale) {
      debugPrint(
        '[FeedStartupCache] status=skip_connected_stale_warm_snapshot '
        'count=${warmSeed.length} targetCount=$effectiveLimit',
      );
      return hadWarmSnapshot;
    }
    final useFreshConnectedWarmSnapshot = ContentPolicy.isConnected &&
        !snapshot.isStale &&
        snapshot.source == CachedResourceSource.server &&
        warmSeed.length >= effectiveLimit;
    final allowPartialWarmSnapshotQuickFill = warmSeed.length >=
            _startupWarmSnapshotMinimumQuickFillCount(effectiveLimit) &&
        !snapshot.isStale;
    final useFastWarmSnapshotSeed =
        useFreshConnectedWarmSnapshot || allowPartialWarmSnapshotQuickFill;
    if (!_hasStartupVariationRoom(warmSeed, targetCount: effectiveLimit) &&
        !useFastWarmSnapshotSeed) {
      debugPrint(
        '[FeedStartupCache] status=skip_warm_snapshot_insufficient_variation '
        'count=${warmSeed.length} targetCount=$effectiveLimit',
      );
      return hadWarmSnapshot;
    }
    if (useFreshConnectedWarmSnapshot) {
      debugPrint(
        '[FeedStartupCache] status=use_connected_fresh_warm_snapshot '
        'count=${warmSeed.length} targetCount=$effectiveLimit '
        'source=${snapshot.source.name}',
      );
    } else if (allowPartialWarmSnapshotQuickFill) {
      debugPrint(
        '[FeedStartupCache] status=use_partial_warm_snapshot '
        'count=${warmSeed.length} targetCount=$effectiveLimit '
        'minimumCount=${_startupWarmSnapshotMinimumQuickFillCount(effectiveLimit)} '
        'source=${snapshot.source.name} stale=${snapshot.isStale}',
      );
    }
    final startupCandidates = useFastWarmSnapshotSeed
        ? warmSeed
        : await _profileFeedStartupCacheStep(
            'augment_support_from_warm_snapshot',
            () => _augmentStartupSupportCandidates(
              candidates: warmSeed,
              nowMs: nowMs,
              primaryCutoffMs: _agendaCutoffMs(nowMs),
              targetCount: effectiveLimit,
              preferCache: true,
              cacheOnly: true,
              allowNetworkFallbackFetch: true,
            ),
          );

    final quickFiltered = _composeStartupFeedItems(
      cacheCandidates: startupCandidates,
      targetCount: effectiveLimit,
    );
    if (quickFiltered.isEmpty) return hadWarmSnapshot;
    final quickFilled = await _profileFeedStartupCacheStep(
      'hydrate_author_identity_from_warm_snapshot',
      () => _hydrateStartupAuthorIdentityFromCache(quickFiltered),
    );
    final warmSnapshotSupportDeficits = _startupSupportDeficits(
      quickFilled,
      targetCount: effectiveLimit,
    );
    final warmSnapshotHasSupportCoverage =
        _startupWarmSnapshotCoverageSatisfied(
      warmSnapshotSupportDeficits,
    );
    if (useFreshConnectedWarmSnapshot && !warmSnapshotHasSupportCoverage) {
      debugPrint(
        '[FeedStartupCache] status=warm_snapshot_missing_support '
        'deficits=$warmSnapshotSupportDeficits targetCount=$effectiveLimit',
      );
    }
    _startupLiveHeadApplied =
        useFreshConnectedWarmSnapshot && warmSnapshotHasSupportCoverage;

    final shouldActivateStartupStages = agendaList.isEmpty;
    if (shouldActivateStartupStages) {
      _startupRenderBootstrapHold = true;
      _activateStartupRenderStages(
        reason: 'quick_fill_warm_snapshot',
      );
    }
    _addUniqueToAgenda(quickFilled);
    _reorderAgendaForStartupPresentationIfNeeded();
    if (_needsInitialFeedPlaybackPrime) {
      primeInitialCenteredPost();
    }
    _applyStartupRenderStagesNow();
    _scheduleBufferedFeedBlockPrefetchAfterFrame(
      reason: 'quick_fill_warm_snapshot',
    );
    _scheduleStartupQuickFillFollowUps(quickFilled);
    _scheduleStartupAvatarHintPrime(
      quickFilled,
      source: 'prime_avatar_hints_from_warm_snapshot_deferred',
    );

    if (agendaList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (agendaList.isNotEmpty &&
            (_needsInitialFeedPlaybackPrime || centeredIndex.value == -1)) {
          primeInitialCenteredPost();
        }
      });
    }
    return hadWarmSnapshot;
  }

  Future<void> _revalidateQuickFilledAgenda(List<PostsModel> shown) async {
    if (shown.isEmpty ||
        !ContentPolicy.allowBackgroundRefresh(ContentScreenKind.feed)) {
      debugPrint(
        '[FeedStartupHeadSync] source=quick_fill_revalidate status=skipped '
        'shownEmpty=${shown.isEmpty} '
        'backgroundRefreshAllowed=${ContentPolicy.allowBackgroundRefresh(ContentScreenKind.feed)}',
      );
      return;
    }
    try {
      final protectVisibleAgenda =
          ContentPolicy.isConnected && agendaList.isNotEmpty;
      debugPrint(
        '[FeedStartupHeadSync] source=quick_fill_revalidate status=begin '
        'protectVisibleAgenda=$protectVisibleAgenda '
        'startupPresentationApplied=$_startupPresentationApplied '
        'startupLiveHeadApplied=$_startupLiveHeadApplied '
        'agendaCount=${agendaList.length} shownCount=${shown.length}',
      );
      if (protectVisibleAgenda && !_startupLiveHeadApplied) {
        try {
          await syncFeedHeadAfterSurfaceOpen();
        } catch (_) {}
      }
      final valid = await _validatePoolPostsAndPrune(shown);
      final validIds = valid.map((p) => p.docID).toSet();
      if (validIds.length == shown.length) return;

      final toRemove = shown
          .where((post) => !validIds.contains(post.docID))
          .map((post) => post.docID)
          .toSet();
      if (toRemove.isEmpty) return;

      if (protectVisibleAgenda) return;

      agendaList.removeWhere((post) => toRemove.contains(post.docID));
    } catch (_) {}
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
        agendaList.removeWhere((p) => toRemove.contains(p.docID));
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

  Future<void> _saveFeedPostsToPool(
      List<PostsModel> posts, Map<String, Map<String, dynamic>> _,
      {CachedResourceSource source = CachedResourceSource.server}) async {
    if (posts.isEmpty) return;
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) return;
    await _feedSnapshotRepository.persistHomeSnapshot(
      userId: userId,
      posts: posts,
      limit: ReadBudgetRegistry.feedPersistSnapshotLimit,
      source: source,
    );
  }

  Future<void> persistWarmLaunchCache() async {
    try {
      if (agendaList.isEmpty) return;
      final indexPool = IndexPoolStore.maybeFind();
      if (indexPool == null) return;

      final posts = _buildOrderedAgendaSnapshot(
        limit: ReadBudgetRegistry.feedPersistSnapshotLimit,
      );
      if (posts.isEmpty) return;

      final userIds = <String>{
        for (final post in posts) post.userID,
        for (final post in posts)
          if (post.originalUserID.isNotEmpty) post.originalUserID,
      }.toList();

      final userMeta = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        final profileCache = ensureUserProfileCacheService();
        final cachedProfiles = await profileCache.getProfiles(
          userIds,
          preferCache: true,
          cacheOnly: true,
        );
        userMeta.addAll(cachedProfiles);
      }

      await _saveFeedPostsToPool(
        posts,
        userMeta,
        source: CachedResourceSource.memory,
      );
    } catch (_) {}
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
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      return _loadLegacyAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        startAfter: startAfter,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
    }

    var effectiveFollowingIds = followingIDs.toSet();
    if (effectiveFollowingIds.isEmpty && !cacheOnly && startAfter == null) {
      effectiveFollowingIds = await _loadStartupFollowingIds(uid);
    }

    final page = await _feedSnapshotRepository.fetchHomePage(
      userId: uid,
      followingIds: effectiveFollowingIds,
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

  List<PostsModel> _buildOrderedAgendaSnapshot({required int limit}) {
    final ordered = agendaList.toList(growable: false)
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return ordered.take(limit).toList(growable: false);
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

  Future<void> hydrateInitialFeedFromCache({int? targetCount}) async {
    if (agendaList.isNotEmpty) return;
    await _tryQuickFillFromCache(limit: targetCount);
  }
}
