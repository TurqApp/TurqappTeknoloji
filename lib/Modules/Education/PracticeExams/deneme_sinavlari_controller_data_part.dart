part of 'deneme_sinavlari_controller.dart';

extension DenemeSinavlariControllerDataPart on DenemeSinavlariController {
  String _listingSelectionKeyForImpl(String uid) =>
      '${DenemeSinavlariController._listingSelectionPrefKeyPrefix}_$uid';

  Future<void> _restoreListingSelectionImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      listingSelection.value = 1;
      listingSelectionReady.value = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_listingSelectionKeyForImpl(uid));
      listingSelection.value = stored == null ? 1 : (stored == 1 ? 1 : 0);
    } catch (_) {
      listingSelection.value = 1;
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
        _listingSelectionKeyForImpl(uid),
        listingSelection.value == 1 ? 1 : 0,
      );
    } catch (_) {}
  }

  Future<void> _bootstrapInitialDataImpl() async {
    final savedController = SavedPracticeExamsController.ensure(
      permanent: true,
    );
    await savedController.loadSavedExams(silent: true);
    final userId = CurrentUserService.instance.effectiveUserId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _practiceExamSnapshotRepository
        .openHome(
          userId: userId,
          limit: DenemeSinavlariController._pageSize,
        )
        .listen(_applyHomeSnapshotResourceImpl);
  }

  Future<void> _getOkulBilgisiImpl() async {
    try {
      final data = await _userSummaryResolver.resolve(
        CurrentUserService.instance.effectiveUserId,
        preferCache: true,
      );
      final rozet = data?.rozet;
      okul.value =
          hasRozetPermission(currentRozet: rozet, minimumRozet: "Sarı");
    } catch (e) {
      AppSnackbar('common.error'.tr, 'practice.school_info_failed'.tr);
    }
  }

  Future<CachedResource<List<SinavModel>>> _loadHomeSnapshotImpl() {
    return _practiceExamSnapshotRepository.loadHome(
      userId: CurrentUserService.instance.effectiveUserId,
      limit: DenemeSinavlariController._pageSize,
    );
  }

  Future<PracticeExamPage> _fetchNextPageImpl() {
    return _practiceExamRepository.fetchPage(
      startAfter: _lastDocument,
      limit: DenemeSinavlariController._pageSize,
    );
  }

  void _applyHomeSnapshotResourceImpl(
      CachedResource<List<SinavModel>> resource) {
    final items = resource.data ?? const <SinavModel>[];
    if (items.isNotEmpty) {
      if (!_sameExamList(items)) {
        list.assignAll(items);
      }
      hasMore.value = items.length >= DenemeSinavlariController._pageSize;
    }

    if (!resource.isRefreshing || items.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (list.isEmpty) {
      isLoading.value = true;
    }
  }
}

extension DenemeSinavlariControllerSearchPart on DenemeSinavlariController {
  void _setupScrollControllerImpl() {
    scrollController.addListener(() {
      final currentOffset = scrollController.position.pixels;
      scrollOffset.value = currentOffset;

      if (currentOffset > _previousOffset) {
        if (showButons.value) showButons.value = false;
        if (ustBar.value) ustBar.value = false;
      } else if (currentOffset < _previousOffset) {
        if (showButons.value) showButons.value = false;
        if (!ustBar.value) ustBar.value = true;
      }

      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !hasActiveSearch &&
          !isLoadingMore.value &&
          hasMore.value) {
        loadMore();
      }

      _previousOffset = currentOffset;
    });
  }

  void _setSearchQueryImpl(String query) {
    searchQuery.value = query.trim();
    _searchDebounce?.cancel();
    if (!hasActiveSearch) {
      isSearchLoading.value = false;
      searchResults.clear();
      _searchToken++;
      return;
    }

    final token = ++_searchToken;
    isSearchLoading.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _searchFromTypesenseImpl(searchQuery.value, token);
    });
  }

  Future<void> _searchFromTypesenseImpl(String query, int token) async {
    final normalized = query.trim();
    try {
      final resource = await _practiceExamSnapshotRepository.search(
        query: normalized,
        userId: CurrentUserService.instance.effectiveUserId,
        limit: 40,
        forceSync: true,
      );
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }

      final results = resource.data ?? const <SinavModel>[];
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }
      if (!_sameExamEntries(searchResults, results)) {
        searchResults.assignAll(results);
      }
    } catch (e) {
      log("Deneme typesense search error: $e");
      if (token == _searchToken) {
        searchResults.clear();
      }
    } finally {
      if (token == _searchToken) {
        isSearchLoading.value = false;
      }
    }
  }
}
