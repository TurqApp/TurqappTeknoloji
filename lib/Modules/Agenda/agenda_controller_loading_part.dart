part of 'agenda_controller.dart';

extension AgendaControllerLoadingPart on AgendaController {
  bool _isTransientAgendaUnavailable(Object error) {
    if (error is FirebaseException && error.code == 'unavailable') {
      return true;
    }
    final message = normalizeLowercase(error.toString());
    return message.contains('cloud_firestore/unavailable') ||
        message.contains('unable to resolve host firestore.googleapis.com') ||
        message.contains('unknownhostexception') ||
        message.contains('the service is currently unavailable');
  }

  void _clearAgendaRetry() {
    _agendaRetryTimer?.cancel();
    _agendaRetryTimer = null;
    _agendaRetryCount = 0;
  }

  void _scheduleAgendaRetry({required bool initial}) {
    if (_agendaRetryTimer?.isActive == true) return;
    _agendaRetryCount = (_agendaRetryCount + 1).clamp(1, 5);
    final delaySeconds = min(30, _agendaRetryCount * 3);
    _agendaRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      _agendaRetryTimer = null;
      if (isClosed) return;
      unawaited(fetchAgendaBigData(initial: initial));
    });
  }

  // Yeni yüklenen gönderileri en üste almak için güvenli yenileme
  Future<void> prependUploadedAndRefresh() async {
    try {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
      await refreshAgenda();
    } catch (e) {
      print('prependUploadedAndRefresh error: $e');
    }
  }

  Future<void> fetchAgendaBigData({bool initial = false}) async {
    final previousAgenda = agendaList.toList(growable: false);
    final previousReshares = publicReshareEvents.toList(growable: false);
    final previousFeedReshares = feedReshareEntries.toList(growable: false);
    final previousLastDoc = lastDoc;
    final previousHasMore = hasMore.value;
    final previousUsePrimaryFeedPaging = _usePrimaryFeedPaging;

    if (initial) {
      lastDoc = null;
      _usePrimaryFeedPaging = true;
      hasMore.value = true;
      _prefetchedThumbnailPostCount = 0;
      agendaList.clear();
      _shuffleCache.clear();
      // Eski yeniden paylaşım meta verilerini sıfırla
      publicReshareEvents.clear();
      feedReshareEntries.clear();

      // 🎯 INSTAGRAM STYLE: İlk açılışta centered index'i sıfırla
      centeredIndex.value = -1;

      // Hızlı ilk boya için: cache'ten doldurmayı dene (gizlilik güvenli)
      try {
        await _tryQuickFillFromCache();
      } catch (e) {
        // Sessizce devam et, sunucu isteğine geçilecek
        // print("quick cache fill error: $e");
      }

      // İlk yüklemede reshare eventlerini arka planda getir (feed'i bloklamasın)
      unawaited(_fetchAndMergeReshareEvents(eventLimit: 200));

      if (agendaList.isNotEmpty &&
          !ContentPolicy.shouldBootstrapNetwork(
            ContentScreenKind.feed,
            hasLocalContent: true,
          )) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            primeInitialCenteredPost();
          }
        });
        return;
      }
    }

    // Eğer shuffle edilmiş postlar varsa onlardan devam et
    if (_shuffleCache.hasBufferedItems) {
      if (!hasMore.value || isLoading.value) return;
      isLoading.value = true;

      try {
        final nextBatch = _shuffleCache.takeNext(fetchLimit);
        _addUniqueToAgenda(nextBatch);
        if (!_shuffleCache.hasMore) {
          hasMore.value = false;
        }
      } finally {
        isLoading.value = false;
      }
      return;
    }

    if (!hasMore.value || isLoading.value) return;

    isLoading.value = true;
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      final loadLimit = initial ? 30 : fetchLimit;
      final page = await _loadAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: loadLimit,
      );
      final visibleItems = page.items;

      _usePrimaryFeedPaging = page.usesPrimaryFeed;
      lastDoc = page.lastDoc;

      if (visibleItems.isNotEmpty) {
        unawaited(
          _saveFeedPostsToPool(
            visibleItems,
            const <String, Map<String, dynamic>>{},
          ),
        );
        // Yeni eklenecekler içinde "zamanlıydı ve yeni görünür oldu" olanları vurgula
        final existingIDs = agendaList.map((e) => e.docID).toSet();
        final toAdd = <PostsModel>[];
        final freshScheduled = <String>[];
        final tenMinAgo = nowMs - const Duration(minutes: 15).inMilliseconds;
        for (final p in visibleItems) {
          final isNew = !existingIDs.contains(p.docID);
          if (!isNew) continue;
          toAdd.add(p);
          final wasScheduled = p.timeStamp != 0;
          final justBecameVisible = wasScheduled && p.timeStamp >= tenMinAgo;
          if (justBecameVisible) {
            freshScheduled.add(p.docID);
          }
        }
        if (freshScheduled.isNotEmpty) {
          markHighlighted(freshScheduled,
              keepFor: const Duration(milliseconds: 900));
        }
        if (toAdd.isNotEmpty) {
          _addUniqueToAgenda(toAdd);
          // Fetch recent reshare events for these posts (followers or public users)
          // Fire and forget
          fetchResharesForPosts(toAdd, perPostLimit: 1);
        }
      }

      if (page.lastDoc == null || visibleItems.length < loadLimit) {
        hasMore.value = false;
      }
      _clearAgendaRetry();
    } catch (e) {
      print("fetchAgendaBigData error: $e");
      if (_isTransientAgendaUnavailable(e)) {
        if (agendaList.isEmpty && previousAgenda.isNotEmpty) {
          agendaList.assignAll(previousAgenda);
          publicReshareEvents.assignAll(previousReshares);
          feedReshareEntries.assignAll(previousFeedReshares);
          lastDoc = previousLastDoc;
          hasMore.value = previousHasMore;
          _usePrimaryFeedPaging = previousUsePrimaryFeedPaging;
          if (centeredIndex.value == -1) {
            primeInitialCenteredPost();
          }
        }
        _scheduleAgendaRetry(initial: initial && agendaList.isEmpty);
      }
    } finally {
      isLoading.value = false; // HER DURUMDA EN SON ÇALIŞIR

      // 🎯 INSTAGRAM STYLE: İlk açılışta ilk videoyu otomatik centered yap
      if (initial && agendaList.isNotEmpty) {
        // Bir frame bekle ki VisibilityDetector build olsun
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            primeInitialCenteredPost();
          }
        });
      }
    }
  }

  Future<void> ensureInitialFeedLoaded() async {
    if (agendaList.isNotEmpty ||
        isLoading.value ||
        _ensureInitialLoadInFlight) {
      return;
    }

    final now = DateTime.now();
    if (_lastEnsureInitialLoadAt != null &&
        now.difference(_lastEnsureInitialLoadAt!) <
            const Duration(seconds: 2)) {
      return;
    }
    _lastEnsureInitialLoadAt = now;
    _ensureInitialLoadInFlight = true;
    try {
      await fetchAgendaBigData(initial: true);
    } finally {
      _ensureInitialLoadInFlight = false;
    }
  }

  // Cache-first: başlangıçta cache'te varsa hızlıca ilk 10 gönderiyi doldur
  Future<void> _tryQuickFillFromCache() async {
    await _tryQuickFillFromPool();
    if (agendaList.isNotEmpty) return;

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
    // Duplicate'e düşmemek için mevcut ID'leri kontrol et
    final existingIDs = agendaList.map((e) => e.docID).toSet();
    final toAdd =
        filtered.where((p) => !existingIDs.contains(p.docID)).toList();
    if (toAdd.isNotEmpty) {
      _addUniqueToAgenda(toAdd);
      unawaited(_revalidateQuickFilledAgenda(toAdd));
      // Reshare'leri gecikmeli getir (açılışta bant genişliğini kritik sorgulara bırak)
      Future.delayed(const Duration(seconds: 2), () {
        fetchResharesForPosts(toAdd, perPostLimit: 1);
      });

      // 🎯 INSTAGRAM STYLE: Cache'den yüklendiğinde de ilk videoyu centered yap
      if (agendaList.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            primeInitialCenteredPost();
          }
        });
      }
    }
  }

  Future<void> _tryQuickFillFromPool() async {
    final me = CurrentUserService.instance.userId;
    if (me.isEmpty) return;
    final snapshot = await _feedSnapshotRepository.bootstrapHome(
      userId: me,
      limit: ContentPolicy.initialPoolLimit(ContentScreenKind.feed),
    );
    final quickFiltered = snapshot.data ?? const <PostsModel>[];
    if (quickFiltered.isEmpty) return;

    _addUniqueToAgenda(quickFiltered);
    unawaited(_revalidateQuickFilledAgenda(quickFiltered));

    if (agendaList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (agendaList.isNotEmpty && centeredIndex.value == -1) {
          primeInitialCenteredPost();
        }
      });
    }
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

  /// Pool fill sonrası arka planda: validasyon, gizlilik prune, reshare fetch
  // ignore: unused_element
  Future<void> _postPoolFillCleanup(
      List<PostsModel> originalPool, List<PostsModel> shown) async {
    try {
      // Validasyon: silinmiş/arşivlenmiş postları pool'dan temizle
      final valid = await _validatePoolPostsAndPrune(originalPool);
      final validIds = valid.map((p) => p.docID).toSet();

      // Toplu gizlilik kontrolü (whereIn ile, tek tek değil)
      final uniqueUserIDs = valid.map((e) => e.userID).toSet().toList();
      final Map<String, bool> userPrivacy = {};
      final Map<String, bool> userDeactivated = {};
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
          includeMeta: false,
        );
      }

      // Gösterilen ama aslında geçersiz/gizli olan postları feed'den kaldır
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
        final isPrivate = userPrivacy[post.userID] ?? false;
        final canSeeAuthor = _visibilityPolicy.canViewerSeeAuthorFromSummary(
          authorUserId: post.userID,
          followingIds: followingIDs,
          isPrivate: isPrivate,
          isDeleted: false,
        );
        if (!canSeeAuthor) {
          toRemove.add(post.docID);
        }
      }

      if (toRemove.isNotEmpty) {
        agendaList.removeWhere((p) => toRemove.contains(p.docID));
      }

      // Reshare'leri gecikmeli getir (bant genişliği çakışmasını önle)
      Future.delayed(const Duration(seconds: 2), () {
        fetchResharesForPosts(agendaList.take(10).toList(), perPostLimit: 1);
      });
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
    final userId = CurrentUserService.instance.userId;
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
    final uid = CurrentUserService.instance.userId;
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

  Future<void> refreshAgenda() async {
    try {
      // Refresh başlarken tüm oynatımları kesin durdur.
      pauseAll.value = true;
      final currentCentered = centeredIndex.value;
      if (currentCentered >= 0 && currentCentered < agendaList.length) {
        _pendingCenteredDocId = agendaList[currentCentered].docID;
      } else if (lastCenteredIndex != null &&
          lastCenteredIndex! >= 0 &&
          lastCenteredIndex! < agendaList.length) {
        _pendingCenteredDocId = agendaList[lastCenteredIndex!].docID;
      }
      centeredIndex.value = -1;
      try {
        VideoStateManager.instance.pauseAllVideos(force: true);
      } catch (_) {}

      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }

      // Following/reshare verilerini yenile (SWR)
      final uid = CurrentUserService.instance.userId;
      if (uid.isNotEmpty) unawaited(_fetchFollowingAndReshares(uid));

      // İlk açılış pipeline'ını kullan: hızlı cache + sunucudan güncel veri.
      await fetchAgendaBigData(initial: true);
      await _fetchAndMergeReshareEvents(eventLimit: 500);
      pauseAll.value = false;
    } catch (e) {
      print("refreshAgenda error: $e");
      pauseAll.value = false;
    }
  }

  // Refresh sırasında karışık gönderi getir - HIZLI VERSİYON
  Future<void> fetchRandomizedAgendaData() async {
    try {
      // Cache kontrolü - eğer cache geçerliyse ve karışık postlar varsa hızlı yükle
      if (_shuffleCache.isFresh && _shuffleCache.hasBufferedItems) {
        print("Cache'den hızlı yükleme yapılıyor...");
        _shuffleCache.reshuffle();

        final initialItems = _shuffleCache.takeNext(fetchLimit);
        _addUniqueToAgenda(initialItems);
        hasMore.value = _shuffleCache.hasMore;

        // 🎯 INSTAGRAM STYLE: Cache'den yüklendiğinde ilk videoyu centered yap
        if (agendaList.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (agendaList.isNotEmpty && centeredIndex.value == -1) {
              primeInitialCenteredPost();
            }
          });
        }
        return;
      }

      print("Yeni veri çekiliyor...");

      // İlk olarak küçük bir batch çek (hızlı görünüm için)
      await _fetchInitialShuffledBatch();

      // Arka planda daha fazla veri çek
      _fetchMoreShuffledDataInBackground();
    } catch (e) {
      print("fetchRandomizedAgendaData error: $e");
    }
  }

  // İlk küçük batch'i hızlıca getir
  Future<void> _fetchInitialShuffledBatch() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = _agendaCutoffMs(nowMs);
    final page = await _postRepository.fetchAgendaWindowPage(
      cutoffMs: cutoffMs,
      nowMs: nowMs,
      limit: _shuffleCache.initialFetchSize,
    );

    final publicIzBirakPosts = await _fetchVisiblePublicIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: _shuffleCache.initialFetchSize,
    );

    final items = <PostsModel>[
      ...page.items,
      ...publicIzBirakPosts,
    ]
        .where((p) => _isEligibleAgendaPost(p, nowMs))
        .where((p) => p.deletedPost != true)
        .toList();

    // Gizlilik kontrolü - sadece gerekli kullanıcılar için
    final visibleItemsRaw = await _filterPrivateItems(items);

    // DocID bazında tekilleştir
    final Map<String, PostsModel> uniqueMap = {
      for (final p in visibleItemsRaw) p.docID: p,
    };
    final visibleItems = uniqueMap.values.toList();

    // Karıştır ve göster
    visibleItems.shuffle(Random());
    _shuffleCache.replace(visibleItems);

    final initialItems = _shuffleCache.takeNext(fetchLimit);
    _addUniqueToAgenda(initialItems);
    hasMore.value = _shuffleCache.hasMore;

    // 🎯 INSTAGRAM STYLE: İlk batch yüklendiğinde ilk videoyu centered yap
    if (agendaList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (agendaList.isNotEmpty && centeredIndex.value == -1) {
          primeInitialCenteredPost();
        }
      });
    }
  }

  // Arka planda daha fazla veri çek
  void _fetchMoreShuffledDataInBackground() async {
    try {
      // 2-3 saniye bekle ki kullanıcı hızlı görünümü görsün
      await Future.delayed(const Duration(seconds: 2));

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      final page = await _postRepository.fetchAgendaWindowPage(
        cutoffMs: cutoffMs,
        nowMs: nowMs,
        limit: _shuffleCache.backgroundFetchSize,
      );

      final publicIzBirakPosts = await _fetchVisiblePublicIzBirakPosts(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: _shuffleCache.backgroundFetchSize,
      );

      final items = <PostsModel>[
        ...page.items,
        ...publicIzBirakPosts,
      ]
          .where((p) => _isEligibleAgendaPost(p, nowMs))
          .where((p) => p.deletedPost != true)
          .toList();

      final visibleItemsRaw = await _filterPrivateItems(items);
      // DocID bazında tekilleştir
      final Map<String, PostsModel> uniqueMap = {
        for (final p in visibleItemsRaw) p.docID: p,
      };
      final visibleItems = uniqueMap.values.toList();

      // Mevcut gösterilenleri koru, kalanları güncelle
      visibleItems.shuffle(Random());
      _shuffleCache.mergeBackground(visibleItems);
      hasMore.value = _shuffleCache.hasMore;
      print(
          "Arka plan yüklemesi tamamlandı: ${_shuffleCache.takeCurrentVisible().length} görünür, buffer hazır");
    } catch (e) {
      print("Background fetch error: $e");
    }
  }

  // Gizlilik filtreleme - optimize edilmiş
  Future<List<PostsModel>> _filterPrivateItems(List<PostsModel> items) async {
    final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();
    Map<String, bool> userPrivacy = {};
    Map<String, bool> userDeactivated = {};

    if (uniqueUserIDs.isNotEmpty) {
      final unresolved = _primeAgendaUserStateFromCaches(
        uniqueUserIDs,
        userPrivacy,
        userDeactivated,
        <String, Map<String, dynamic>>{},
      );
      if (unresolved.isNotEmpty) {
        await _fillAgendaUserStateFromProfiles(
          unresolved,
          userPrivacy,
          userDeactivated,
          <String, Map<String, dynamic>>{},
          includeMeta: false,
        );
      }
    }

    return items.where((post) {
      if (hiddenPosts.contains(post.docID)) return false;
      if (post.deletedPost == true) return false;
      if (!_isRenderablePost(post)) return false;
      if (userDeactivated[post.userID] == true) return false;
      final isPrivate = userPrivacy[post.userID] ?? false;
      return _visibilityPolicy.canViewerSeeAuthorFromSummary(
        authorUserId: post.userID,
        followingIds: followingIDs,
        isPrivate: isPrivate,
        isDeleted: false,
      );
    }).toList();
  }
}
