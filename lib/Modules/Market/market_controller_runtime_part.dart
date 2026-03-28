part of 'market_controller.dart';

extension MarketControllerRuntimePart on MarketController {
  Future<void> _bootstrapHomeData() => _performBootstrapHomeData();

  Future<void> prepareStartupSurface({bool? allowBackgroundRefresh}) =>
      _performPrepareStartupSurface(
        allowBackgroundRefresh: allowBackgroundRefresh,
      );

  Future<void> loadHomeData({
    bool forceRefresh = false,
    bool silent = false,
  }) =>
      _performLoadHomeData(
        forceRefresh: forceRefresh,
        silent: silent,
      );

  void setSearchQuery(String value) => _performSetSearchQuery(value);

  void applyRecentSearch(String value) => _performApplyRecentSearch(value);

  Future<void> clearRecentSearches() => _performClearRecentSearches();

  int _compareCategoryPriority(String left, String right) =>
      _performCompareCategoryPriority(left, right);

  int _preferredCategoryIndex(String label) =>
      _performPreferredCategoryIndex(label);

  String _categoryOrderKey(String value) => _performCategoryOrderKey(value);

  bool _isVisibleCategory(Map<String, dynamic> category) =>
      _performIsVisibleCategory(category);

  void toggleListingSelection() => _performToggleListingSelection();

  void selectCategory(String key) => _performSelectCategory(key);

  void clearCategoryFilter() => _performClearCategoryFilter();

  Future<void> openItem(MarketItemModel item) => _performOpenItem(item);

  bool isSaved(String itemId) => savedItemIds.contains(itemId);

  Future<void> toggleSaved(
    MarketItemModel item, {
    bool showSnackbar = true,
  }) =>
      _performToggleSaved(item, showSnackbar: showSnackbar);

  Future<void> openRoundMenu(String key) => _performOpenRoundMenu(key);

  void showComingSoon(String title) => _performShowComingSoon(title);

  void applyAdvancedFilters({
    required String city,
    required String contactPreference,
    required String minPrice,
    required String maxPrice,
    required String sortBy,
  }) =>
      _performApplyAdvancedFilters(
        city: city,
        contactPreference: contactPreference,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
      );

  void clearAdvancedFilters() => _performClearAdvancedFilters();

  void refreshFilters() => _performRefreshFilters();

  Future<void> refreshHome() => _performRefreshHome();

  Future<void> focusNearbyItems() => _performFocusNearbyItems();

  void _applyFilters() => _performApplyFilters();

  bool _matchesCategory(MarketItemModel item, String categoryKey) =>
      _performMatchesCategory(item, categoryKey);

  Future<void> _searchFromTypesense(String query, int requestId) =>
      _performSearchFromTypesense(query, requestId);

  Future<void> _loadRecentSearches() => _performLoadRecentSearches();

  Future<void> _storeRecentSearch(String query) =>
      _performStoreRecentSearch(query);

  Future<void> _loadListingFromSnapshot({
    bool forceRefresh = false,
  }) =>
      _performLoadListingFromSnapshot(forceRefresh: forceRefresh);

  Future<void> _reloadListingForCurrentFilters() =>
      _performReloadListingForCurrentFilters();

  Future<void> _applyHomeSnapshotResource(
    CachedResource<List<MarketItemModel>> resource,
  ) =>
      _performApplyHomeSnapshotResource(resource);

  Future<void> _loadAllCityOptions() => _performLoadAllCityOptions();

  bool _isLatestSearch(int requestId, String query) =>
      _performIsLatestSearch(requestId, query);

  bool _matchesLocalQuery(MarketItemModel item, String query) =>
      _performMatchesLocalQuery(item, query);

  int _compareItems(MarketItemModel a, MarketItemModel b) =>
      _performCompareItems(a, b);

  Future<void> _loadSavedItems() => _performLoadSavedItems();

  Future<void> _loadRoundMenuBadges({required bool forceRefresh}) =>
      _performLoadRoundMenuBadges(forceRefresh: forceRefresh);

  void _applyLocalFavoriteDelta(String itemId, int delta) =>
      _performApplyLocalFavoriteDelta(itemId, delta);

  List<MarketItemModel> _updateFavoriteCount(
    List<MarketItemModel> source,
    String itemId,
    int delta,
  ) =>
      _performUpdateFavoriteCount(source, itemId, delta);

  void _upsertVisibleItem(MarketItemModel item) =>
      _performUpsertVisibleItem(item);

  List<MarketItemModel> _mergePendingCreatedItems(
    List<MarketItemModel> source,
  ) =>
      _performMergePendingCreatedItems(source);

  MarketItemModel _preserveProtectedFields(
    MarketItemModel remote,
    MarketItemModel local,
  ) =>
      _performPreserveProtectedFields(remote, local);

  bool _isSyncedWithPending(
    MarketItemModel remote,
    MarketItemModel local,
  ) =>
      _performIsSyncedWithPending(remote, local);

  void _onScroll() => _performOnScroll();

  String get _currentUid {
    return CurrentUserService.instance.effectiveUserId;
  }
}
