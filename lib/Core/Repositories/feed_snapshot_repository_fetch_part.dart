part of 'feed_snapshot_repository.dart';

extension FeedSnapshotRepositoryFetchPart on FeedSnapshotRepository {
  int _feedHomeCutoffMs(int nowMs) =>
      nowMs - const Duration(days: 7).inMilliseconds;

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
    String locationCity = '',
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedLocationCity = locationCity.trim();
    if (!usePrimaryFeedPaging) {
      if (_shouldLogDiagnostics) {
        debugPrint(
          '[FeedManifestPrimary] status=manifest_only_skip '
          'usePrimaryFeedPaging=$usePrimaryFeedPaging '
          'uid=${normalizedUserId.isNotEmpty}',
        );
      }
      return const FeedSourcePage(
        items: <PostsModel>[],
        lastDoc: null,
        usesPrimaryFeed: true,
        itemsPreplanned: true,
        nextTypesensePage: null,
      );
    }

    if (primarySourceOverride == FeedPrimarySourceMode.typesense &&
        normalizedLocationCity.isNotEmpty &&
        startAfter == null &&
        (typesensePage == null || typesensePage <= 1)) {
      return _loadCityTypesenseSeedPage(
        currentUserId: normalizedUserId,
        followingIds: followingIds,
        hiddenPostIds: hiddenPostIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        locationCity: normalizedLocationCity,
      );
    }

    final manifestPage = await _tryLoadFeedManifestPrimaryPage(
      currentUserId: normalizedUserId,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      startAfter: startAfter,
      cacheOnly: cacheOnly,
      typesensePage: typesensePage,
    );
    if (manifestPage != null) {
      return manifestPage;
    }
    final shouldUseFallback =
        startAfter == null && (typesensePage == null || typesensePage <= 1);
    if (shouldUseFallback) {
      if (normalizedUserId.isNotEmpty) {
        final warmFallback = await _loadWarmFeedFallbackPage(
          currentUserId: normalizedUserId,
          followingIds: followingIds,
          hiddenPostIds: hiddenPostIds,
          nowMs: nowMs,
          cutoffMs: cutoffMs,
          limit: limit,
        );
        if (warmFallback.items.isNotEmpty) {
          if (_shouldLogDiagnostics) {
            debugPrint(
              '[FeedManifestPrimary] status=fallback_warm '
              'uid=$normalizedUserId count=${warmFallback.items.length}',
            );
          }
          return warmFallback;
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
          if (_shouldLogDiagnostics) {
            debugPrint(
              '[FeedManifestPrimary] status=fallback_personal '
              'uid=$normalizedUserId count=${personalFallback.items.length}',
            );
          }
          return personalFallback;
        }
      }
    }
    if (_shouldLogDiagnostics) {
      debugPrint(
        '[FeedManifestPrimary] status=manifest_only_empty '
        'uid=$normalizedUserId page=${typesensePage ?? 1}',
      );
    }
    return const FeedSourcePage(
      items: <PostsModel>[],
      lastDoc: null,
      usesPrimaryFeed: true,
      itemsPreplanned: true,
      nextTypesensePage: null,
    );
  }

  Future<FeedSourcePage?> _tryLoadFeedManifestPrimaryPage({
    required String currentUserId,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required DocumentSnapshot<Map<String, dynamic>>? startAfter,
    required bool cacheOnly,
    required int? typesensePage,
  }) async {
    if (!FeedManifestPolicy.primaryEnabled || cacheOnly) {
      return null;
    }

    final startedAt = DateTime.now();
    final pageNumber = typesensePage != null && typesensePage > 0
        ? typesensePage
        : (startAfter == null ? 1 : 2);
    final pageWindow = FeedSnapshotRepository.resolveManifestPageWindow(
      pageNumber: pageNumber,
      pageSize: limit,
    );
    final deckLimit = pageWindow.deckLimit;
    final pageStart = pageWindow.pageStart;
    final pageEndExclusive = pageWindow.pageEndExclusive;
    final slotLoadBudget = FeedManifestPolicy.resolveSlotLoadBudget(
      pageNumber: pageNumber,
    );
    final primaryLoadTimeout = FeedManifestPolicy.resolvePrimaryLoadTimeout(
      pageNumber: pageNumber,
      hasAuthUser: currentUserId.trim().isNotEmpty,
    );
    try {
      final poolFuture = _feedManifestRepository.loadRollingPool(
        maxSlotsToLoad: slotLoadBudget,
      );
      final pool = primaryLoadTimeout == Duration.zero
          ? await poolFuture
          : await poolFuture.timeout(primaryLoadTimeout);
      if (pool.entries.isEmpty) {
        if (_shouldLogDiagnostics) {
          debugPrint('[FeedManifestPrimary] status=empty_pool');
        }
        return null;
      }
      if (_shouldLogDiagnostics) {
        final poolSlotCounts = <String, int>{};
        for (final entry in pool.entries) {
          poolSlotCounts.update(entry.slotPath, (count) => count + 1,
              ifAbsent: () => 1);
        }
        debugPrint(
          '[FeedManifestPrimary] status=pool_slot_distribution '
          'page=$pageNumber slotBudget=$slotLoadBudget '
          'slotCount=${pool.slotCount} loadedSlotCount=${pool.loadedSlotCount} '
          'entryCount=${pool.entries.length} distribution=$poolSlotCounts',
        );
      }

      await _feedDiversityMemory.ensureReady();
      final gapEntries = await _loadFeedManifestGapEntries(
        manifestId: pool.manifestId,
        hiddenPostIds: hiddenPostIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        manifestGeneratedAt: pool.generatedAt,
        primarySlotPath: _resolvePrimarySlotPath(pool.entries),
        limit: limit,
      );
      final seed = FeedManifestPolicy.resolveDeckSeed(
        userId: currentUserId,
        manifestId: pool.manifestId,
        startupSeed: startupSurfaceSessionSeed(sessionNamespace: 'feed'),
      );
      final deck = _feedManifestMixer.buildDeck(
        manifestEntries: pool.entries,
        gapEntries: gapEntries,
        seed: seed,
        limit: deckLimit,
        consumedCanonicalIds: <String>{
          ..._feedDiversityMemory.weeklyWatchedPenaltyDocIds(),
          ..._feedDiversityMemory.weeklyWatchedFloodRootIds(),
        },
        consumedDocIds: _feedDiversityMemory.weeklyWatchedPenaltyDocIds(),
        headPenaltyCanonicalIds: <String>{
          ..._feedDiversityMemory.startupHeadPenaltyDocIds(),
          ..._feedDiversityMemory.startupHeadPenaltyFloodRootIds(),
        },
        gapEvery: FeedManifestPolicy.gapEvery,
        minUserSpacing: FeedManifestPolicy.minUserSpacing,
        maxItemsPerUser: FeedManifestPolicy.maxItemsPerUser,
      );
      final consumedDocIds = _feedDiversityMemory.weeklyWatchedPenaltyDocIds();
      final consumedFloodRootIds =
          _feedDiversityMemory.weeklyWatchedFloodRootIds();
      final visibleEntries = _selectVisibleFeedManifestEntries(
        manifestEntries: pool.entries,
        gapEntries: gapEntries,
        hiddenPostIds: hiddenPostIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: deckLimit,
        consumedDocIds: consumedDocIds,
        consumedFloodRootIds: consumedFloodRootIds,
        newestManifestSlotPath: _resolvePrimarySlotPath(pool.entries),
      );
      _state.latestVisibleSourceByDocId = Map<String, String>.unmodifiable({
        for (final deckEntry in visibleEntries)
          deckEntry.post.docID.trim(): deckEntry.entry.slotPath.trim(),
      });
      final visible =
          visibleEntries.map((entry) => entry.post).toList(growable: false);
      if (_shouldLogDiagnostics && visibleEntries.isNotEmpty) {
        final visibleSlotCounts = <String, int>{};
        for (final entry in visibleEntries) {
          visibleSlotCounts.update(entry.entry.slotPath, (count) => count + 1,
              ifAbsent: () => 1);
        }
        debugPrint(
          '[FeedManifestPrimary] status=visible_slot_distribution '
          'page=$pageNumber pageStart=$pageStart pageEnd=$pageEndExclusive '
          'visibleCount=${visible.length} distribution=$visibleSlotCounts',
        );
      }
      if (visible.isEmpty || pageStart >= visible.length) {
        if (_shouldLogDiagnostics) {
          debugPrint(
            '[FeedManifestPrimary] status=empty_visible '
            'page=$pageNumber pool=${pool.entries.length} '
            'deck=${deck.entries.length}',
          );
        }
        return null;
      }
      final pageItems =
          visible.skip(pageStart).take(limit).toList(growable: false);
      if (pageItems.isEmpty) {
        return null;
      }
      final pageVisibleEntries =
          visibleEntries.skip(pageStart).take(limit).toList(growable: false);
      if (_shouldLogDiagnostics && pageVisibleEntries.isNotEmpty) {
        final topPreview = pageVisibleEntries.take(5).map((entry) {
          final post = entry.post;
          final ageMinutes = max(
            0,
            ((nowMs - post.timeStamp.toInt()) / const Duration(minutes: 1).inMilliseconds)
                .floor(),
          );
          final slotPath = entry.entry.slotPath.trim();
          final slotLabel = slotPath == 'typesense_gap' ? 'gap' : slotPath;
          return '$slotLabel:${post.docID}:age=${ageMinutes}m';
        }).join(' | ');
        debugPrint(
          '[FeedManifestPrimary] status=top_page_preview '
          'page=$pageNumber preview=$topPreview',
        );
      }
      if (pageNumber == 1) {
        _feedDiversityMemory.rememberStartupHead(
          pageItems,
          limit: FeedManifestPolicy.startupHeadRememberLimit,
        );
      }
      final hasPotentialMore = deck.entries.length >= deckLimit &&
          (pool.entries.length > deck.manifestCount ||
              gapEntries.length > deck.gapCount);
      final nextPage = visible.length > pageEndExclusive || hasPotentialMore
          ? pageNumber + 1
          : null;
      if (_shouldLogDiagnostics) {
        final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
        final totalVisibleGapCount = visibleEntries
            .where((entry) => entry.source == FeedManifestDeckSource.gap)
            .length;
        final pageGapCount = pageVisibleEntries
            .where((entry) => entry.source == FeedManifestDeckSource.gap)
            .length;
        final pageSlotFillCount = pageItems.length - pageGapCount;
        debugPrint(
          '[FeedManifestPrimary] status=ok elapsedMs=$elapsedMs '
          'page=$pageNumber nextPage=${nextPage ?? 0} '
          'manifest=${pool.manifestId} slots=${pool.loadedSlotCount}/${pool.slotCount} '
          'timeoutMs=${primaryLoadTimeout.inMilliseconds} '
          'slotBudget=$slotLoadBudget '
          'pool=${pool.entries.length} gap=${deck.gapCount} '
          'visible=${visible.length} returned=${pageItems.length} '
          'skippedConsumed=${deck.skippedConsumedCount} '
          'skippedDuplicate=${deck.skippedDuplicateCount}',
        );
        debugPrint(
          '[GAP_FINAL] page=$pageNumber manifest=${pool.manifestId} '
          'raw=${gapEntries.length} visible=$totalVisibleGapCount '
          'pageGap=$pageGapCount pageSlotFill=$pageSlotFillCount '
          'returned=${pageItems.length}',
        );
        _state.lastGapFinalSummary =
            '[GAP_FINAL] page=$pageNumber manifest=${pool.manifestId} '
            'raw=${gapEntries.length} visible=$totalVisibleGapCount '
            'pageGap=$pageGapCount pageSlotFill=$pageSlotFillCount '
            'returned=${pageItems.length}';
      }
      return FeedSourcePage(
        items: pageItems,
        lastDoc: null,
        usesPrimaryFeed: true,
        itemsPreplanned: true,
        nextTypesensePage: nextPage,
      );
    } catch (error) {
      if (_shouldLogDiagnostics) {
        final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
        debugPrint(
          '[FeedManifestPrimary] status=fail elapsedMs=$elapsedMs '
          'page=$pageNumber timeoutMs=${primaryLoadTimeout.inMilliseconds} '
          'slotBudget=$slotLoadBudget error=$error',
        );
      }
      return null;
    }
  }

  Future<FeedSourcePage> _loadWarmFeedFallbackPage({
    required String currentUserId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
  }) async {
    final posts = await _warmLaunchPool.loadPosts(
      IndexPoolKind.feed,
      limit: limit,
      allowStale: true,
    );
    if (posts.isEmpty) {
      return const FeedSourcePage(
        items: <PostsModel>[],
        lastDoc: null,
        usesPrimaryFeed: false,
        itemsPreplanned: true,
        nextTypesensePage: null,
      );
    }
    final visible = await filterVisiblePosts(
      posts,
      currentUserId: currentUserId,
      followingIds: followingIds,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      summaryCacheOnly: true,
      refreshNonPublicCachedSummaries: false,
    );
    return FeedSourcePage(
      items: visible,
      lastDoc: null,
      usesPrimaryFeed: false,
      itemsPreplanned: true,
      nextTypesensePage: null,
    );
  }

  Future<List<FeedManifestEntry>> _loadFeedManifestGapEntries({
    required String manifestId,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int manifestGeneratedAt,
    required String primarySlotPath,
    required int limit,
  }) async {
    if (!FeedManifestPolicy.typesenseGapEnabled) {
      return const <FeedManifestEntry>[];
    }
    final slotWindow = _resolveGapSlotWindow(
      primarySlotPath: primarySlotPath,
      fallbackGeneratedAt: manifestGeneratedAt,
    );
    final gapWindowStartMs =
        slotWindow.startMs + FeedManifestPolicy.gapWindowDelay.inMilliseconds;
    final gapCacheUntilMs = slotWindow.endMs;
    if (nowMs <= gapWindowStartMs) {
      return const <FeedManifestEntry>[];
    }
    if (nowMs >= gapCacheUntilMs) {
      return const <FeedManifestEntry>[];
    }
    final effectiveNowMs = min(nowMs, gapCacheUntilMs);
    final gapCutoffMs = max(cutoffMs, gapWindowStartMs);
    if (gapCutoffMs >= effectiveNowMs) {
      return const <FeedManifestEntry>[];
    }
    final cacheKey = '${slotWindow.cacheKey}:$gapWindowStartMs:$gapCacheUntilMs';
    if (_state.gapWindowCacheKey == cacheKey &&
        _state.gapWindowCacheFuture == null &&
        nowMs < gapCacheUntilMs) {
      if (_shouldLogDiagnostics) {
        debugPrint(
          '[FeedManifestPrimary] gap_status=cache_hit '
          'manifest=$manifestId count=${_state.gapWindowCacheEntries.length} '
          'windowStart=$gapWindowStartMs cacheUntil=$gapCacheUntilMs',
        );
      }
      return _state.gapWindowCacheEntries;
    }
    final persisted = await _readPersistedGapEntries(
      cacheKey: cacheKey,
      nowMs: nowMs,
    );
    if (persisted.isNotEmpty) {
      _state.gapWindowCacheKey = cacheKey;
      _state.gapWindowCacheEntries = persisted;
      if (_shouldLogDiagnostics) {
        debugPrint(
          '[FeedManifestPrimary] gap_status=disk_cache_hit '
          'manifest=$manifestId count=${persisted.length} '
          'windowStart=$gapWindowStartMs cacheUntil=$gapCacheUntilMs',
        );
      }
      return persisted;
    }
    if (_state.gapWindowCacheKey == cacheKey &&
        _state.gapWindowCacheFuture != null &&
        nowMs < gapCacheUntilMs) {
      return _state.gapWindowCacheFuture!;
    }
    final ownedMinutes = List<int>.generate(60, (index) => index);
    final candidateLimit = FeedManifestPolicy.resolveGapCandidateLimit(limit);
    final loadFuture = () async {
      try {
        final motorPage = await _postRepository.fetchTypesenseMotorCandidates(
          surface: 'feed',
          ownedMinutes: ownedMinutes,
          limit: candidateLimit,
          page: 1,
          nowMs: effectiveNowMs,
          cutoffMs: gapCutoffMs,
        );
        final visible = _filterFeedManifestDeckPosts(
          motorPage.items,
          hiddenPostIds: hiddenPostIds,
          nowMs: effectiveNowMs,
          cutoffMs: gapCutoffMs,
          limit: candidateLimit,
        );
        final entries = visible
            .map(
              (post) => FeedManifestMixer.entryFromPost(
                post,
                slotId: 'typesense_gap',
                slotPath: 'typesense_gap',
              ),
            )
            .toList(growable: false);
        _state.gapWindowCacheKey = cacheKey;
        _state.gapWindowCacheEntries = entries;
        await _persistGapEntries(
          cacheKey: cacheKey,
          cacheUntilMs: gapCacheUntilMs,
          entries: entries,
        );
        if (_shouldLogDiagnostics) {
          debugPrint(
            '[FeedManifestPrimary] gap_status=ready '
            'manifest=$manifestId rawFetched=${motorPage.items.length} '
            'filteredVisible=${visible.length} count=${entries.length} '
            'windowStart=$gapWindowStartMs '
            'cacheUntil=$gapCacheUntilMs',
          );
          debugPrint(
            '[GAP] status=ready '
            'manifest=$manifestId raw=${motorPage.items.length} '
            'filtered=${visible.length} cached=${entries.length}',
          );
        }
        return entries;
      } catch (error) {
        if (_shouldLogDiagnostics) {
          debugPrint('[FeedManifestPrimary] gap_status=fail error=$error');
        }
        return const <FeedManifestEntry>[];
      } finally {
        if (_state.gapWindowCacheKey == cacheKey) {
          _state.gapWindowCacheFuture = null;
        }
      }
    }();
    _state.gapWindowCacheKey = cacheKey;
    _state.gapWindowCacheFuture = loadFuture;
    return loadFuture;
  }

  String _resolvePrimarySlotPath(List<FeedManifestEntry> entries) {
    var best = '';
    for (final entry in entries) {
      final slotPath = entry.slotPath.trim();
      if (slotPath.isEmpty || slotPath == 'typesense_gap') continue;
      if (best.isEmpty ||
          FeedManifestMixer.compareSlotKeysNewestFirst(slotPath, best) < 0) {
        best = slotPath;
      }
    }
    return best;
  }

  ({int startMs, int endMs, String cacheKey}) _resolveGapSlotWindow({
    required String primarySlotPath,
    required int fallbackGeneratedAt,
  }) {
    final match = RegExp(r'(\d{4}-\d{2}-\d{2}).*slot_(\d{2})')
        .firstMatch(primarySlotPath);
    if (match != null) {
      final day = DateTime.tryParse('${match.group(1)}T00:00:00');
      final hour = int.tryParse(match.group(2) ?? '');
      if (day != null && hour != null) {
        final start = DateTime(
          day.year,
          day.month,
          day.day,
          hour,
        );
        return (
          startMs: start.millisecondsSinceEpoch,
          endMs: start
              .add(FeedManifestRepository.manifestWindowCadence)
              .millisecondsSinceEpoch,
          cacheKey: '${match.group(1)}:slot_$hour',
        );
      }
    }
    final fallbackStart = DateTime.fromMillisecondsSinceEpoch(
      fallbackGeneratedAt,
    );
    final normalized = DateTime(
      fallbackStart.year,
      fallbackStart.month,
      fallbackStart.day,
      fallbackStart.hour - (fallbackStart.hour % 3),
    );
    return (
      startMs: normalized.millisecondsSinceEpoch,
      endMs: normalized
          .add(FeedManifestRepository.manifestWindowCadence)
          .millisecondsSinceEpoch,
      cacheKey:
          '${normalized.year}-${normalized.month}-${normalized.day}:slot_${normalized.hour}',
    );
  }

  Future<SharedPreferences> _ensureGapPrefs() async {
    final existing = _state.prefs;
    if (existing != null) return existing;
    final prefs = await SharedPreferences.getInstance();
    _state.prefs = prefs;
    return prefs;
  }

  Future<List<FeedManifestEntry>> _readPersistedGapEntries({
    required String cacheKey,
    required int nowMs,
  }) async {
    try {
      final prefs = await _ensureGapPrefs();
      final raw = prefs.getString(FeedSnapshotRepository._gapWindowPrefsKey);
      if (raw == null || raw.isEmpty) return const <FeedManifestEntry>[];
      final json = jsonDecode(raw);
      if (json is! Map) return const <FeedManifestEntry>[];
      final map = Map<String, dynamic>.from(json.cast<dynamic, dynamic>());
      final savedKey = (map['cacheKey'] ?? '').toString().trim();
      final cacheUntilMs = int.tryParse('${map['cacheUntilMs'] ?? 0}') ?? 0;
      if (savedKey != cacheKey || cacheUntilMs <= nowMs) {
        await prefs.remove(FeedSnapshotRepository._gapWindowPrefsKey);
        return const <FeedManifestEntry>[];
      }
      final payload = Map<String, dynamic>.from(
        (map['payload'] as Map?)?.cast<dynamic, dynamic>() ??
            const <dynamic, dynamic>{},
      );
      final posts = _decodePosts(payload);
      return posts
          .map(
            (post) => FeedManifestMixer.entryFromPost(
              post,
              slotId: 'typesense_gap',
              slotPath: 'typesense_gap',
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const <FeedManifestEntry>[];
    }
  }

  Future<void> _persistGapEntries({
    required String cacheKey,
    required int cacheUntilMs,
    required List<FeedManifestEntry> entries,
  }) async {
    try {
      final prefs = await _ensureGapPrefs();
      final payload = _encodePosts(
        entries.map((entry) => entry.post).toList(growable: false),
      );
      await prefs.setString(
        FeedSnapshotRepository._gapWindowPrefsKey,
        jsonEncode(<String, dynamic>{
          'cacheKey': cacheKey,
          'cacheUntilMs': cacheUntilMs,
          'payload': payload,
        }),
      );
    } catch (_) {}
  }

  List<PostsModel> _filterFeedManifestDeckPosts(
    List<PostsModel> posts, {
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
  }) {
    if (posts.isEmpty || limit <= 0) return const <PostsModel>[];
    final visible = <PostsModel>[];
    final seen = <String>{};
    for (final post in posts) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seen.add(docId)) continue;
      if (hiddenPostIds.contains(docId)) continue;
      if (post.userID.trim().isEmpty) continue;
      if (post.deletedPost == true || post.gizlendi) continue;
      if (post.shouldHideWhileUploading) continue;
      if (!_isRenderablePost(post)) continue;
      if (!_isInAgendaWindow(post.timeStamp.toInt(), nowMs, cutoffMs)) {
        continue;
      }
      if (post.timeStamp > nowMs) continue;
      visible.add(post);
      if (visible.length >= limit) break;
    }
    return visible;
  }

  List<FeedManifestDeckEntry> _selectVisibleFeedManifestEntries({
    required List<FeedManifestEntry> manifestEntries,
    required List<FeedManifestEntry> gapEntries,
    required Set<String> hiddenPostIds,
    required Set<String> consumedDocIds,
    required Set<String> consumedFloodRootIds,
    required String newestManifestSlotPath,
    required int nowMs,
    required int cutoffMs,
    required int limit,
  }) {
    if ((manifestEntries.isEmpty && gapEntries.isEmpty) || limit <= 0) {
      return const <FeedManifestDeckEntry>[];
    }

    final manifestBuckets = <String, List<FeedManifestDeckEntry>>{};
    final gapBucket = <FeedManifestDeckEntry>[];
    final slotOrder = <String>[];
    final seenCanonicals = <String>{};
    final seenDocIds = <String>{};
    final skippedConsumedDocIds = <String>[];
    final skippedConsumedFloodRootIds = <String>[];
    var rawGapCount = 0;
    var consumedPrunedGapCount = 0;

    void considerEntry(
      FeedManifestEntry entry,
      FeedManifestDeckSource source,
    ) {
      final post = entry.post;
      if (source == FeedManifestDeckSource.gap) {
        rawGapCount++;
      }
      final docId = post.docID.trim();
      final canonicalId = entry.canonicalId.trim();
      if (docId.isEmpty || canonicalId.isEmpty) return;
      if (!seenDocIds.add(docId)) return;
      if (!seenCanonicals.add(canonicalId)) return;
      if (hiddenPostIds.contains(docId)) return;
      if (consumedDocIds.contains(docId)) {
        if (source == FeedManifestDeckSource.gap) {
          consumedPrunedGapCount++;
        }
        if (skippedConsumedDocIds.length < 8) {
          skippedConsumedDocIds.add(docId);
        }
        return;
      }
      final floodRootId = post.isFloodSeriesContent
          ? (post.mainFlood.trim().isNotEmpty
              ? post.mainFlood.trim()
              : (post.isFloodSeriesRoot
                  ? docId
                  : docId.replaceFirst(RegExp(r'_\d+$'), '')))
          : '';
      if (floodRootId.isNotEmpty &&
          consumedFloodRootIds.contains(floodRootId)) {
        if (source == FeedManifestDeckSource.gap) {
          consumedPrunedGapCount++;
        }
        if (skippedConsumedFloodRootIds.length < 8) {
          skippedConsumedFloodRootIds.add(floodRootId);
        }
        return;
      }
      if (post.userID.trim().isEmpty) return;
      if (post.deletedPost == true || post.gizlendi) return;
      if (post.shouldHideWhileUploading) return;
      if (!_isRenderablePost(post)) return;
      if (!_isInAgendaWindow(post.timeStamp.toInt(), nowMs, cutoffMs)) {
        return;
      }
      if (post.timeStamp > nowMs) return;

      final deckEntry = FeedManifestDeckEntry(
        entry: entry,
        source: source,
      );
      if (source == FeedManifestDeckSource.gap) {
        gapBucket.add(deckEntry);
        return;
      }

      final slotKey = entry.slotPath.trim().isNotEmpty
          ? entry.slotPath.trim()
          : entry.slotId.trim();
      if (slotKey.isEmpty) {
        return;
      }
      final bucket = manifestBuckets.putIfAbsent(slotKey, () {
        slotOrder.add(slotKey);
        return <FeedManifestDeckEntry>[];
      });
      bucket.add(deckEntry);
    }

    for (final entry in gapEntries) {
      considerEntry(entry, FeedManifestDeckSource.gap);
    }

    for (final entry in manifestEntries) {
      considerEntry(entry, FeedManifestDeckSource.manifest);
    }

    if (_shouldLogDiagnostics &&
        (skippedConsumedDocIds.isNotEmpty ||
            skippedConsumedFloodRootIds.isNotEmpty)) {
      debugPrint(
        '[FeedManifestPrimary] status=consumed_visible_prune '
        'skippedDocs=${skippedConsumedDocIds.length} '
        'skippedFloodRoots=${skippedConsumedFloodRootIds.length} '
        'docPreview=$skippedConsumedDocIds '
        'floodPreview=$skippedConsumedFloodRootIds',
      );
    }
    slotOrder.sort(FeedManifestMixer.compareSlotKeysNewestFirst);
    for (final bucket in manifestBuckets.values) {
      bucket.sort((left, right) {
        final timeCompare =
            right.post.timeStamp.toInt().compareTo(left.post.timeStamp.toInt());
        if (timeCompare != 0) return timeCompare;
        return right.post.docID.compareTo(left.post.docID);
      });
    }
    gapBucket.sort((left, right) {
      final timeCompare =
          right.post.timeStamp.toInt().compareTo(left.post.timeStamp.toInt());
      if (timeCompare != 0) return timeCompare;
      return right.post.docID.compareTo(left.post.docID);
    });

    final selected = <FeedManifestDeckEntry>[];
    if (gapBucket.isNotEmpty) {
      final remaining = limit - selected.length;
      final takeCount = min(
        FeedManifestPolicy.gapSlotBatchSize,
        min(gapBucket.length, remaining),
      );
      if (takeCount > 0) {
        selected.addAll(gapBucket.take(takeCount));
      }
    }
    for (var slotIndex = 0; slotIndex < slotOrder.length; slotIndex++) {
      final slotKey = slotOrder[slotIndex];
      final bucket = manifestBuckets[slotKey];
      final remaining = limit - selected.length;
      if (remaining <= 0) break;
      final hasLaterAvailable = slotOrder.skip(slotIndex + 1).any(
            (key) => (manifestBuckets[key]?.isNotEmpty ?? false),
          );
      if (bucket == null || bucket.isEmpty) {
        if (_shouldLogDiagnostics && hasLaterAvailable) {
          debugPrint(
            '[FeedManifestPrimary] status=slot_exhausted_bypass '
            'slot=${slotIndex + 1} slotPath=$slotKey '
            'reason=empty remaining=$remaining',
          );
        }
        continue;
      }
      final takeCount = min(
        FeedManifestMixer.defaultSlotBatchSize,
        min(bucket.length, remaining),
      );
      selected.addAll(bucket.take(takeCount));
      if (_shouldLogDiagnostics &&
          takeCount < FeedManifestMixer.defaultSlotBatchSize &&
          hasLaterAvailable &&
          remaining > takeCount) {
        debugPrint(
          '[FeedManifestPrimary] status=slot_exhausted_bypass '
          'slot=${slotIndex + 1} slotPath=$slotKey '
          'reason=underfilled takeCount=$takeCount '
          'batchSize=${FeedManifestMixer.defaultSlotBatchSize} '
          'remainingBefore=$remaining',
        );
      }
    }
    if (_shouldLogDiagnostics && rawGapCount > 0) {
      final visibleGapCount = selected
          .where((entry) => entry.source == FeedManifestDeckSource.gap)
          .length;
      debugPrint(
        '[FeedManifestPrimary] gap_status=selection '
        'rawGapCount=$rawGapCount '
        'consumedPrunedGapCount=$consumedPrunedGapCount '
        'visibleGapCount=$visibleGapCount '
        'limit=$limit',
      );
      debugPrint(
        '[GAP] status=selection '
        'raw=$rawGapCount pruned=$consumedPrunedGapCount '
        'visible=$visibleGapCount limit=$limit',
      );
    }
    return selected;
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

  Future<FeedSourcePage> _loadCityTypesenseSeedPage({
    required String currentUserId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required String locationCity,
  }) async {
    final cityCandidates = await _postRepository.fetchTypesenseMotorCandidates(
      surface: 'feed',
      ownedMinutes: const <int>[0],
      limit: limit,
      page: 1,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      locationCity: locationCity,
      randomize: true,
      randomWindowDays: 4,
    );
    final visible = await filterVisiblePosts(
      cityCandidates.items,
      currentUserId: currentUserId,
      followingIds: followingIds,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      summaryCacheOnly: false,
      refreshNonPublicCachedSummaries: false,
    );
    return FeedSourcePage(
      items: visible,
      lastDoc: null,
      usesPrimaryFeed: true,
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
