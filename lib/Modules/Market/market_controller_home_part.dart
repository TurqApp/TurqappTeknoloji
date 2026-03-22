part of 'market_controller.dart';

extension _MarketControllerHomePart on MarketController {
  Future<void> _performRestoreListingSelection() async {
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

  Future<void> _performPersistListingSelection() async {
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

  Future<void> _performBootstrapHomeData() async {
    try {
      await _schemaService.loadSchema();
      final loadedCategories = _schemaService
          .categories()
          .where(_isVisibleCategory)
          .toList(growable: true)
        ..sort(
          (a, b) => _compareCategoryPriority(
            (a['label'] ?? '').toString(),
            (b['label'] ?? '').toString(),
          ),
        );
      final roundMenu = _schemaService.roundMenuItems();
      if (!_sameMapList(categories, loadedCategories)) {
        categories.assignAll(loadedCategories);
      }
      if (!_sameMapList(roundMenuItems, roundMenu)) {
        roundMenuItems.assignAll(roundMenu);
      }
    } catch (_) {}
    await _loadSavedItems();
    final userId = CurrentUserService.instance.effectiveUserId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _marketSnapshotRepository
        .openHome(userId: userId, limit: 120)
        .listen((resource) {
      unawaited(_applyHomeSnapshotResource(resource));
    });
  }

  Future<void> _performLoadHomeData({
    required bool forceRefresh,
    required bool silent,
  }) async {
    final shouldShowLoader = !silent && items.isEmpty && visibleItems.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      await _schemaService.loadSchema();
      final loadedCategories = _schemaService
          .categories()
          .where(_isVisibleCategory)
          .toList(growable: true)
        ..sort(
          (a, b) => _compareCategoryPriority(
            (a['label'] ?? '').toString(),
            (b['label'] ?? '').toString(),
          ),
        );
      final roundMenu = _schemaService.roundMenuItems();
      if (!_sameMapList(categories, loadedCategories)) {
        categories.assignAll(loadedCategories);
      }
      if (!_sameMapList(roundMenuItems, roundMenu)) {
        roundMenuItems.assignAll(roundMenu);
      }
      await _loadListingFromSnapshot(forceRefresh: forceRefresh);
      await _loadAllCityOptions();
      await _loadSavedItems();
      await _loadRoundMenuBadges(forceRefresh: forceRefresh);
      _applyFilters();
    } finally {
      if (shouldShowLoader) {
        isLoading.value = false;
      }
    }
  }

  void _performToggleListingSelection() {
    listingSelection.value = listingSelection.value == 0 ? 1 : 0;
    unawaited(_persistListingSelection());
  }

  Future<void> _performRefreshHome() async {
    await loadHomeData(forceRefresh: true);
  }

  Future<void> _performLoadListingFromSnapshot({
    required bool forceRefresh,
  }) async {
    try {
      final fetched = await _marketSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: 120,
        forceSync: forceRefresh,
      );
      final activeFetched = (fetched.data ?? const <MarketItemModel>[])
          .where((item) => item.status == 'active')
          .toList(growable: false);
      final merged = _mergePendingCreatedItems(activeFetched);
      if (!_sameMarketList(merged)) {
        items.assignAll(merged);
      }
    } catch (_) {
      final merged = _mergePendingCreatedItems(const <MarketItemModel>[]);
      if (!_sameMarketList(merged)) {
        items.assignAll(merged);
      }
    }
  }

  Future<void> _performReloadListingForCurrentFilters() async {
    isSearchLoading.value = true;
    try {
      await _loadListingFromSnapshot();
      await _loadAllCityOptions();
      _applyFilters();
    } finally {
      isSearchLoading.value = false;
    }
  }

  Future<void> _performApplyHomeSnapshotResource(
    CachedResource<List<MarketItemModel>> resource,
  ) async {
    final activeItems = (resource.data ?? const <MarketItemModel>[])
        .where((item) => item.status == 'active')
        .toList(growable: false);
    if (activeItems.isNotEmpty) {
      final nextItems = _mergePendingCreatedItems(activeItems);
      if (!_sameMarketList(nextItems)) {
        items.assignAll(nextItems);
        _applyFilters();
      }
      unawaited(_loadAllCityOptions());
      unawaited(_loadSavedItems());
      unawaited(_loadRoundMenuBadges(forceRefresh: false));
    }

    if (!resource.isRefreshing || activeItems.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (items.isEmpty && visibleItems.isEmpty) {
      isLoading.value = true;
    }
  }
}
