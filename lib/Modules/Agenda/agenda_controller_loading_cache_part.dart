part of 'agenda_controller.dart';

extension AgendaControllerLoadingCachePart on AgendaController {
  Future<void> _tryQuickFillFromCache() async {
    final hadWarmSnapshot = await _tryQuickFillFromPool();
    if (agendaList.isNotEmpty) return;

    if (ContentPolicy.isConnected) {
      if (!hadWarmSnapshot) {
        return;
      }
      final me = CurrentUserService.instance.effectiveUserId;
      if (me.isEmpty) return;
      final quickFallback =
          await _feedSnapshotRepository.loadQuickCachedPersonalFallback(
        userId: me,
        followingIds: followingIDs.toSet(),
        hiddenPostIds: hiddenPosts.toSet(),
        limit: ContentPolicy.initialPoolLimit(ContentScreenKind.feed),
      );
      if (quickFallback.isEmpty) return;

      final existingIDs = agendaList.map((e) => e.docID).toSet();
      final toAdd = quickFallback
          .where((p) => !existingIDs.contains(p.docID))
          .toList(growable: false);
      if (toAdd.isEmpty) return;

      _addUniqueToAgenda(toAdd);
      unawaited(_revalidateQuickFilledAgenda(toAdd));
      _scheduleReshareFetchForPosts(toAdd, perPostLimit: 1);

      if (agendaList.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            primeInitialCenteredPost();
          }
        });
      }
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = _agendaCutoffMs(nowMs);
    final page = await _loadAgendaSourcePage(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: fetchLimit,
      preferCache: true,
      cacheOnly: true,
    );
    final filtered = page.items;
    if (filtered.isEmpty) return;
    final existingIDs = agendaList.map((e) => e.docID).toSet();
    final toAdd =
        filtered.where((p) => !existingIDs.contains(p.docID)).toList();
    if (toAdd.isNotEmpty) {
      _addUniqueToAgenda(toAdd);
      unawaited(_revalidateQuickFilledAgenda(toAdd));
      _scheduleReshareFetchForPosts(toAdd, perPostLimit: 1);

      if (agendaList.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            primeInitialCenteredPost();
          }
        });
      }
    }
  }

  Future<bool> _tryQuickFillFromPool() async {
    final me = CurrentUserService.instance.effectiveUserId;
    if (me.isEmpty) return false;
    final snapshot = await _feedSnapshotRepository.bootstrapHome(
      userId: me,
      limit: ContentPolicy.initialPoolLimit(ContentScreenKind.feed),
    );
    final hadWarmSnapshot = snapshot.hasLocalSnapshot;
    final quickFiltered = snapshot.data ?? const <PostsModel>[];
    if (quickFiltered.isEmpty) return hadWarmSnapshot;

    _addUniqueToAgenda(quickFiltered);
    unawaited(_revalidateQuickFilledAgenda(quickFiltered));

    if (agendaList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (agendaList.isNotEmpty && centeredIndex.value == -1) {
          primeInitialCenteredPost();
        }
      });
    }
    return hadWarmSnapshot;
  }

  Future<void> _revalidateQuickFilledAgenda(List<PostsModel> shown) async {
    if (shown.isEmpty ||
        !ContentPolicy.allowBackgroundRefresh(ContentScreenKind.feed)) {
      return;
    }
    try {
      final valid = await _validatePoolPostsAndPrune(shown);
      final validIds = valid.map((p) => p.docID).toSet();
      if (validIds.length == shown.length) return;

      final toRemove = shown
          .where((post) => !validIds.contains(post.docID))
          .map((post) => post.docID)
          .toSet();
      if (toRemove.isEmpty) return;

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
    List<PostsModel> posts,
    Map<String, Map<String, dynamic>> _,
  ) async {
    if (posts.isEmpty) return;
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) return;
    await _feedSnapshotRepository.persistHomeSnapshot(
      userId: userId,
      posts: posts,
      limit: 40,
      source: CachedResourceSource.server,
    );
  }

  Future<void> persistWarmLaunchCache() async {
    try {
      if (agendaList.isEmpty) return;
      final indexPool = IndexPoolStore.maybeFind();
      if (indexPool == null) return;

      final posts = agendaList.take(40).toList(growable: false);
      if (posts.isEmpty) return;

      final userIds = <String>{
        for (final post in posts) post.userID,
        for (final post in posts)
          if (post.originalUserID.isNotEmpty) post.originalUserID,
      }.toList();

      final userMeta = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        final profileCache = UserProfileCacheService.ensure();
        final cachedProfiles = await profileCache.getProfiles(
          userIds,
          preferCache: true,
          cacheOnly: true,
        );
        userMeta.addAll(cachedProfiles);
      }

      await _saveFeedPostsToPool(posts, userMeta);
    } catch (_) {}
  }

  Future<_AgendaSourcePage> _loadAgendaSourcePage({
    required int nowMs,
    required int cutoffMs,
    required int limit,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      return _loadLegacyAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
    }

    final page = await _feedSnapshotRepository.fetchHomePage(
      userId: uid,
      followingIds: followingIDs.toSet(),
      hiddenPostIds: hiddenPosts.toSet(),
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      startAfter: lastDoc is DocumentSnapshot<Map<String, dynamic>>
          ? lastDoc as DocumentSnapshot<Map<String, dynamic>>
          : null,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
      usePrimaryFeedPaging: _usePrimaryFeedPaging,
    );
    return _AgendaSourcePage(
      items: page.items,
      lastDoc: page.lastDoc,
      usesPrimaryFeed: page.usesPrimaryFeed,
    );
  }

  Future<_AgendaSourcePage> _loadLegacyAgendaSourcePage({
    required int nowMs,
    required int cutoffMs,
    required int limit,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final page = await _postRepository.fetchAgendaWindowPage(
      cutoffMs: cutoffMs,
      nowMs: nowMs,
      limit: limit,
      startAfter: lastDoc,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    return _AgendaSourcePage(
      items: page.items
          .where((p) => _isEligibleAgendaPost(p, nowMs))
          .where((p) => p.deletedPost != true)
          .toList(growable: false),
      lastDoc: page.lastDoc,
      usesPrimaryFeed: false,
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
