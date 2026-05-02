part of 'scholarships_controller.dart';

extension _ScholarshipsControllerDataPart on ScholarshipsController {
  void _performHydrateScholarshipsStartupSeedPoolSync() {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    try {
      final shard = ensureStartupSnapshotSeedPool().load(
        surface: 'scholarships',
        userId: userId,
      );
      if (shard == null) return;
      final decoded = _decodeScholarshipStartupItems(shard.payload['items']);
      if (decoded.isEmpty) return;
      if (allScholarships.isEmpty) {
        allScholarships.assignAll(decoded);
      }
      if (visibleScholarships.isEmpty) {
        _setVisibleScholarships(decoded);
      }
    } catch (_) {}
  }

  Future<void> _performHydrateScholarshipsStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    try {
      final shard = await ensureStartupSnapshotShardStore().load(
        surface: 'scholarships',
        userId: userId,
        maxAge: StartupSnapshotShardStore.defaultFreshWindow,
      );
      if (shard == null) return;
      final decoded = _decodeScholarshipStartupItems(shard.payload['items']);
      if (decoded.isEmpty) return;
      if (allScholarships.isEmpty) {
        allScholarships.assignAll(decoded);
      }
      if (visibleScholarships.isEmpty) {
        _setVisibleScholarships(decoded);
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _decodeScholarshipStartupItems(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((entry) {
          final item = Map<String, dynamic>.from(
            entry.cast<dynamic, dynamic>(),
          );
          final modelMap =
              Map<String, dynamic>.from(item['model'] as Map? ?? const {});
          final docId = (item['docId'] ?? '').toString().trim();
          if (docId.isEmpty) return null;
          return <String, dynamic>{
            'model': IndividualScholarshipsModel.fromJson(modelMap),
            'type': (item['type'] ?? kIndividualScholarshipType).toString(),
            'userData': Map<String, dynamic>.from(
              item['userData'] as Map? ?? const <String, dynamic>{},
            ),
            'docId': docId,
            'likesCount': item['likesCount'] ?? 0,
            'bookmarksCount': item['bookmarksCount'] ?? 0,
            'timeStamp': item['timeStamp'] ?? 0,
            'isSummary': item['isSummary'] == true,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Future<void> _persistScholarshipsStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final startupLimit = ReadBudgetRegistry.startupListingWarmLimit(
      onWiFi: true,
    );
    final startupItems = allScholarships
        .take(startupLimit)
        .toList(growable: false);
    final store = ensureStartupSnapshotShardStore();
    if (startupItems.isEmpty) {
      await store.clear(surface: 'scholarships', userId: userId);
      return;
    }
    await store.save(
      surface: 'scholarships',
      userId: userId,
      itemCount: allScholarships.length,
      limit: startupLimit,
      source: 'scholarship_snapshot',
      payload: <String, dynamic>{
        'items': startupItems
            .map((item) {
              final model = item['model'] as IndividualScholarshipsModel?;
              return <String, dynamic>{
                'docId': item['docId'] ?? '',
                'type': item['type'] ?? kIndividualScholarshipType,
                'model': model?.toJson() ?? <String, dynamic>{},
                'userData': Map<String, dynamic>.from(
                  item['userData'] as Map? ?? const <String, dynamic>{},
                ),
                'likesCount': item['likesCount'] ?? 0,
                'bookmarksCount': item['bookmarksCount'] ?? 0,
                'timeStamp': item['timeStamp'] ?? 0,
                'isSummary': item['isSummary'] ?? false,
              };
            })
            .toList(growable: false),
      },
    );
  }

  String _listingSelectionKeyFor(String uid) =>
      '${ScholarshipsController._listingSelectionPrefKeyPrefix}_$uid';

  Future<void> _restoreListingSelectionImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      listingSelection.value = 0;
      listingSelectionReady.value = true;
      return;
    }
    try {
      final stored = await _localPreferenceRepository.getInt(
        _listingSelectionKeyFor(uid),
      );
      listingSelection.value = stored == 1 ? 1 : 0;
    } catch (_) {
      listingSelection.value = 0;
    } finally {
      listingSelectionReady.value = true;
    }
  }

  Future<void> _persistListingSelectionImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      await _localPreferenceRepository.setInt(
        _listingSelectionKeyFor(uid),
        listingSelection.value == 1 ? 1 : 0,
      );
    } catch (_) {}
  }

  void _toggleListingSelectionImpl() {
    listingSelection.value = listingSelection.value == 0 ? 1 : 0;
    unawaited(_persistListingSelection());
  }

  Future<void> _refreshTotalCountImpl() async {
    if (allScholarships.isNotEmpty) {
      totalCount.value = totalCount.value < allScholarships.length
          ? allScholarships.length
          : totalCount.value;
      return;
    }
    try {
      final result = await _scholarshipSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: 1,
      );
      totalCount.value = result.data?.found ?? 0;
    } catch (_) {}
  }

  void _setSearchQueryImpl(String q) {
    searchQuery.value = q.trim();
    _searchDebounce?.cancel();
    if (!_scholarshipsHasActiveSearch(this)) {
      isSearching.value = false;
      _setVisibleScholarships(allScholarships);
      return;
    }

    final requestToken = ++_searchRequestToken;
    isSearching.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _searchFromTypesense(searchQuery.value, requestToken);
    });
  }

  void _resetSearchImpl() {
    _searchDebounce?.cancel();
    _searchRequestToken++;
    searchQuery.value = '';
    isSearching.value = false;
    _setVisibleScholarships(allScholarships);
  }

  void _applyScholarshipStateFromCombined(List<Map<String, dynamic>> combined) {
    allScholarships.clear();
    allScholarships.addAll(combined);
    _setVisibleScholarships(
      _scholarshipsHasActiveSearch(this) ? visibleScholarships : combined,
    );
  }

  void _setVisibleScholarships(List<Map<String, dynamic>> items) {
    visibleScholarships.assignAll(items);
    isExpandedList
      ..clear()
      ..addAll(List<RxBool>.generate(items.length, (_) => false.obs));
    pageIndices
      ..clear()
      ..addAll(
        Map.fromIterables(
          List.generate(items.length, (i) => i),
          List.generate(items.length, (_) => 0.obs),
        ),
      );
  }

  Future<void> _searchFromTypesense(String query, int requestToken) async {
    final normalized = query.trim();
    if (normalized.length < minSearchLength) {
      if (requestToken == _searchRequestToken) {
        isSearching.value = false;
        _setVisibleScholarships(allScholarships);
      }
      return;
    }

    try {
      final result = await _scholarshipSnapshotRepository.search(
        query: normalized,
        userId: CurrentUserService.instance.effectiveUserId,
        limit: ReadBudgetRegistry.scholarshipSearchInitialLimit,
        forceSync: true,
      );
      if (requestToken != _searchRequestToken ||
          searchQuery.value.trim() != normalized) {
        return;
      }

      final items = result.data?.items ?? const <Map<String, dynamic>>[];
      await _primeLocalStateForCombined(items);
      if (requestToken != _searchRequestToken ||
          searchQuery.value.trim() != normalized) {
        return;
      }
      _setVisibleScholarships(items);
    } catch (_) {
      if (requestToken == _searchRequestToken) {
        _setVisibleScholarships(const []);
      }
    } finally {
      if (requestToken == _searchRequestToken) {
        isSearching.value = false;
      }
    }
  }

  Future<void> _primeLocalStateForCombined(
    List<Map<String, dynamic>> items,
  ) async {
    final currentUserId = CurrentUserService.instance.effectiveUserId;
    final followTasks = <Future<void>>[];

    for (final item in items) {
      final docId = (item['docId'] ?? '').toString().trim();
      final model = item['model'] as IndividualScholarshipsModel?;
      final userData = Map<String, dynamic>.from(
        item['userData'] as Map? ?? const <String, dynamic>{},
      );
      final userID =
          (userData['userID'] ?? model?.userID ?? '').toString().trim();
      likedScholarships.putIfAbsent(
        docId,
        () =>
            _likedByCurrentUser.contains(docId) ||
            (currentUserId.isNotEmpty &&
                (model?.begeniler.contains(currentUserId) ?? false)),
      );
      bookmarkedScholarships.putIfAbsent(
        docId,
        () =>
            _bookmarkedByCurrentUser.contains(docId) ||
            (currentUserId.isNotEmpty &&
                (model?.kaydedenler.contains(currentUserId) ?? false)),
      );
      if (currentUserId.isNotEmpty &&
          userID.isNotEmpty &&
          !followedUsers.containsKey(userID)) {
        followTasks.add(() async {
          followedUsers[userID] =
              await _checkFollowStatus(userID, currentUserId);
        }());
      }
    }
    if (followTasks.isNotEmpty) {
      await Future.wait(followTasks);
    }
  }

  Future<bool> _checkFollowStatus(String followedId, String followerId) async {
    return _followRepository.isFollowing(
      followedId,
      currentUid: followerId,
      preferCache: true,
    );
  }

  Future<void> _fetchScholarshipsImpl({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        lastRefresh != null &&
        DateTime.now().difference(lastRefresh!).inSeconds < 2) {
      return;
    }
    lastRefresh = DateTime.now();

    try {
      if (!silent) {
        isLoading.value = true;
      }
      final result = await _scholarshipSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: _scholarshipsInitialBatchSize,
        forceSync: forceRefresh,
      );
      _typesensePage = 1;
      final snapshot = result.data;
      totalCount.value = snapshot?.found ?? 0;
      final combined = snapshot?.items ?? const <Map<String, dynamic>>[];
      await _primeLocalStateForCombined(combined);

      _applyScholarshipStateFromCombined(combined);
      unawaited(_persistScholarshipsStartupShard());
      if (_scholarshipsHasActiveSearch(this)) {
        unawaited(
          _searchFromTypesense(searchQuery.value, ++_searchRequestToken),
        );
      }
      _prefetchShortLinksForList(allScholarships);
      SilentRefreshGate.markRefreshed('scholarships:home');
      hasMoreData.value = combined.length >= _scholarshipsInitialBatchSize &&
          allScholarships.length < totalCount.value;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadMoreScholarshipsImpl() async {
    if (isLoadingMore.value || !hasMoreData.value) {
      return;
    }

    try {
      isLoadingMore.value = true;
      final result = await _scholarshipSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: _scholarshipsBatchSize,
        page: _typesensePage + 1,
        forceSync: true,
      );
      _typesensePage += 1;
      final snapshot = result.data;
      totalCount.value = snapshot?.found ?? totalCount.value;
      final combined = snapshot?.items ?? const <Map<String, dynamic>>[];
      await _primeLocalStateForCombined(combined);

      isExpandedList.addAll(
        List<RxBool>.generate(combined.length, (_) => false.obs),
      );
      final newPageIndices = Map.fromIterables(
        List.generate(combined.length, (i) => allScholarships.length + i),
        List.generate(combined.length, (_) => 0.obs),
      );
      pageIndices.addAll(newPageIndices);

      allScholarships.addAll(combined);
      if (_scholarshipsHasActiveSearch(this)) {
        unawaited(
          _searchFromTypesense(searchQuery.value, ++_searchRequestToken),
        );
      } else {
        _setVisibleScholarships(allScholarships);
      }
      _prefetchShortLinksForList(allScholarships);
      hasMoreData.value = combined.length >= _scholarshipsBatchSize &&
          allScholarships.length < totalCount.value;
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.load_more_failed'.tr);
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _applyHomeSnapshotResource(
    CachedResource<ScholarshipListingSnapshot> resource,
  ) {
    final snapshot = resource.data;
    final items = snapshot?.items ?? const <Map<String, dynamic>>[];
    if (snapshot != null) {
      totalCount.value = snapshot.found;
      _typesensePage = 1;
    }
    if (items.isNotEmpty) {
      unawaited(_primeLocalStateForCombined(items));
      _applyScholarshipStateFromCombined(items);
      unawaited(_persistScholarshipsStartupShard());
      _prefetchShortLinksForList(allScholarships);
      hasMoreData.value = items.length >= _scholarshipsInitialBatchSize &&
          allScholarships.length < totalCount.value;
    }

    if (!resource.isRefreshing || items.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (allScholarships.isEmpty) {
      isLoading.value = true;
    }
  }
}
