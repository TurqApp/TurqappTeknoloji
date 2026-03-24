part of 'agenda_controller.dart';

extension AgendaControllerLoadingShufflePart on AgendaController {
  Future<void> fetchRandomizedAgendaData() async {
    try {
      if (_shuffleCache.isFresh && _shuffleCache.hasBufferedItems) {
        print("Cache'den hızlı yükleme yapılıyor...");
        _shuffleCache.reshuffle();

        final initialItems = _shuffleCache.takeNext(fetchLimit);
        _addUniqueToAgenda(initialItems);
        hasMore.value = _shuffleCache.hasMore;

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
      await _fetchInitialShuffledBatch();
      _fetchMoreShuffledDataInBackground();
    } catch (e) {
      print("fetchRandomizedAgendaData error: $e");
    }
  }

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

    final visibleItemsRaw = await _filterPrivateItems(items);
    final uniqueMap = {
      for (final p in visibleItemsRaw) p.docID: p,
    };
    final visibleItems = uniqueMap.values.toList();

    visibleItems.shuffle(Random());
    _shuffleCache.replace(visibleItems);

    final initialItems = _shuffleCache.takeNext(fetchLimit);
    _addUniqueToAgenda(initialItems);
    hasMore.value = _shuffleCache.hasMore;

    if (agendaList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (agendaList.isNotEmpty && centeredIndex.value == -1) {
          primeInitialCenteredPost();
        }
      });
    }
  }

  void _fetchMoreShuffledDataInBackground() async {
    try {
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
      final uniqueMap = {
        for (final p in visibleItemsRaw) p.docID: p,
      };
      final visibleItems = uniqueMap.values.toList();

      visibleItems.shuffle(Random());
      _shuffleCache.mergeBackground(visibleItems);
      hasMore.value = _shuffleCache.hasMore;
      print(
          "Arka plan yüklemesi tamamlandı: ${_shuffleCache.takeCurrentVisible().length} görünür, buffer hazır");
    } catch (e) {
      print("Background fetch error: $e");
    }
  }

  Future<List<PostsModel>> _filterPrivateItems(List<PostsModel> items) async {
    final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();
    final userPrivacy = <String, bool>{};
    final userDeactivated = <String, bool>{};
    final userMeta = <String, Map<String, dynamic>>{};

    if (uniqueUserIDs.isNotEmpty) {
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
    }

    return items.where((post) {
      if (hiddenPosts.contains(post.docID)) return false;
      if (post.deletedPost == true) return false;
      if (!_isRenderablePost(post)) return false;
      if (userDeactivated[post.userID] == true) return false;
      final meta = userMeta[post.userID] ?? const <String, dynamic>{};
      final rozet =
          (meta['rozet'] ?? meta['badge'] ?? post.rozet).toString().trim();
      final isApproved = meta['isApproved'] == true;
      return _visibilityPolicy.canViewerSeeDiscoveryAuthorFromSummary(
        authorUserId: post.userID,
        followingIds: followingIDs,
        rozet: rozet,
        isApproved: isApproved,
        isDeleted: false,
      );
    }).toList();
  }
}
