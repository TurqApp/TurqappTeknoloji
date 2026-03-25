part of 'scholarships_controller.dart';

extension _ScholarshipsControllerDataPart on ScholarshipsController {
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
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_listingSelectionKeyFor(uid));
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
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
        limit: 40,
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
