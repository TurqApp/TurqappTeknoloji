part of 'market_controller.dart';

extension _MarketControllerFilterPart on MarketController {
  void _performSetSearchQuery(String value) {
    searchQuery.value = value;
    if (search.text != value) {
      search.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    _searchDebounce?.cancel();
    final normalized = value.trim();
    if (normalized.length >= 2) {
      final requestId = ++_searchRequestId;
      isSearchLoading.value = true;
      searchedItems.clear();
      _applyFilters();
      _searchDebounce = Timer(const Duration(milliseconds: 280), () {
        unawaited(_searchFromTypesense(normalized, requestId));
      });
      return;
    }
    _searchRequestId++;
    isSearchLoading.value = false;
    searchedItems.clear();
    _applyFilters();
  }

  void _performApplyRecentSearch(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    setSearchQuery(normalized);
  }

  Future<void> _performClearRecentSearches() async {
    recentSearches.clear();
    final preferences = ensureLocalPreferenceRepository();
    await preferences.remove(_marketRecentSearchesKey);
  }

  int _performCompareCategoryPriority(String left, String right) {
    final leftIndex = _preferredCategoryIndex(left);
    final rightIndex = _preferredCategoryIndex(right);
    if (leftIndex != rightIndex) {
      return leftIndex.compareTo(rightIndex);
    }
    return compareTurkishStrings(left, right);
  }

  int _performPreferredCategoryIndex(String label) {
    final normalized = _categoryOrderKey(label);
    for (var i = 0; i < _marketPreferredCategoryOrder.length; i++) {
      if (_categoryOrderKey(_marketPreferredCategoryOrder[i]) == normalized) {
        return i;
      }
    }
    return _marketPreferredCategoryOrder.length + 100;
  }

  String _performCategoryOrderKey(String value) {
    final normalized = normalizeMarketCategoryLabel(value);
    switch (normalized) {
      case 'kozmetik':
        return normalizeMarketCategoryLabel('Kişisel Bakım');
      default:
        return normalized;
    }
  }

  bool _performIsVisibleCategory(Map<String, dynamic> category) {
    final key = (category['key'] ?? '').toString().trim().toLowerCase();
    return key != 'emlak';
  }

  void _performSelectCategory(String key) {
    final normalized = key.trim();
    selectedCategoryKey.value =
        selectedCategoryKey.value == normalized ? '' : normalized;
    if (searchQuery.value.trim().length >= 2) {
      setSearchQuery(searchQuery.value);
      return;
    }
    _applyFilters();
  }

  void _performClearCategoryFilter() {
    if (selectedCategoryKey.value.isEmpty) {
      _applyFilters();
      return;
    }
    selectedCategoryKey.value = '';
    if (searchQuery.value.trim().length >= 2) {
      setSearchQuery(searchQuery.value);
      return;
    }
    _applyFilters();
  }

  void _performApplyAdvancedFilters({
    required String city,
    required String contactPreference,
    required String minPrice,
    required String maxPrice,
    required String sortBy,
  }) {
    selectedCityFilter.value = city.trim();
    selectedContactFilter.value = contactPreference.trim();
    minPriceFilter.value = minPrice.trim();
    maxPriceFilter.value = maxPrice.trim();
    sortSelection.value = sortBy.trim().isEmpty ? 'newest' : sortBy.trim();
    refreshFilters();
  }

  void _performClearAdvancedFilters() {
    selectedCityFilter.value = '';
    selectedContactFilter.value = '';
    minPriceFilter.value = '';
    maxPriceFilter.value = '';
    sortSelection.value = 'newest';
    refreshFilters();
  }

  void _performRefreshFilters() {
    if (searchQuery.value.trim().length >= 2) {
      setSearchQuery(searchQuery.value);
      return;
    }
    unawaited(_reloadListingForCurrentFilters());
  }

  Future<void> _performFocusNearbyItems() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppSnackbar(
          'pasaj.market.permission_required_title'.tr,
          'pasaj.market.nearby_permission_required'.tr,
        );
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final city = placemarks.isNotEmpty
          ? (placemarks.first.administrativeArea ??
                  placemarks.first.locality ??
                  '')
              .trim()
          : '';
      if (city.isEmpty) {
        AppSnackbar(
          'pasaj.market.location_not_found_title'.tr,
          'pasaj.market.city_not_found'.tr,
        );
        return;
      }

      if (!availableCities.contains(city)) {
        AppSnackbar(
          'pasaj.market.limited_results_title'.tr,
          'pasaj.market.no_city_results'.trParams({'city': city}),
        );
        return;
      }

      selectedCityFilter.value = city;
      refreshFilters();
      AppSnackbar(
        'common.success'.tr,
        'pasaj.market.nearby_ready'.trParams({'city': city}),
      );
    } catch (_) {
      AppSnackbar(
        'common.error'.tr,
        'pasaj.market.nearby_failed'.tr,
      );
    }
  }

  void _performApplyFilters() {
    final query = normalizeSearchText(searchQuery.value);
    final categoryKey = selectedCategoryKey.value.trim();
    final cityFilter = normalizeSearchText(selectedCityFilter.value);
    final contactFilter = selectedContactFilter.value.trim();
    final minPrice = double.tryParse(
          minPriceFilter.value.trim().replaceAll(',', '.'),
        ) ??
        0;
    final maxPriceRaw =
        double.tryParse(maxPriceFilter.value.trim().replaceAll(',', '.'));
    final useRemoteResults = query.length >= 2;
    final source = useRemoteResults ? searchedItems : items;
    final filtered = source.where((item) {
      if (item.status != 'active') return false;
      final matchesCategory = _matchesCategory(item, categoryKey);
      if (!matchesCategory) return false;
      if (cityFilter.isNotEmpty &&
          normalizeSearchText(item.city) != cityFilter) {
        return false;
      }
      if (contactFilter.isNotEmpty && item.contactPreference != contactFilter) {
        return false;
      }
      if (item.price < minPrice) return false;
      if (maxPriceRaw != null && maxPriceRaw > 0 && item.price > maxPriceRaw) {
        return false;
      }
      if (useRemoteResults || query.isEmpty) return true;
      return _matchesLocalQuery(item, query);
    }).toList(growable: false)
      ..sort(_compareItems);
    if (_sameVisibleItems(filtered)) {
      return;
    }
    visibleItems.assignAll(filtered);
  }

  bool _performMatchesCategory(MarketItemModel item, String categoryKey) {
    if (categoryKey.isEmpty) return true;
    if (item.categoryKey == categoryKey ||
        item.categoryKey.startsWith('$categoryKey/')) {
      return true;
    }

    final selectedCategory = categories.firstWhereOrNull(
      (category) => (category['key'] ?? '').toString() == categoryKey,
    );
    final selectedLabel = normalizeSearchText(
      (selectedCategory?['label'] ?? '').toString(),
    );
    if (selectedLabel.isEmpty) return false;

    final topLabel = item.categoryPath.isEmpty
        ? ''
        : normalizeSearchText(item.categoryPath.first);
    if (topLabel == selectedLabel) return true;

    final fullPath = normalizeSearchText(item.categoryPath.join(' '));
    final keyWords = normalizeSearchText(categoryKey.replaceAll('-', ' '));
    return fullPath.contains(selectedLabel) || fullPath.contains(keyWords);
  }

  Future<void> _performSearchFromTypesense(String query, int requestId) async {
    try {
      final fetched = await _marketSnapshotRepository.search(
        query: query,
        userId: CurrentUserService.instance.effectiveUserId,
        limit: ReadBudgetRegistry.marketSearchInitialLimit,
        forceSync: true,
      );
      if (!_isLatestSearch(requestId, query)) return;

      final results = (fetched.data ?? const <MarketItemModel>[])
          .where((item) => item.status == 'active')
          .toList(growable: false);
      if (!_sameMarketEntries(searchedItems, results)) {
        searchedItems.assignAll(results);
      }
      if (results.isNotEmpty) {
        await _storeRecentSearch(query);
      }
    } catch (_) {
      if (!_isLatestSearch(requestId, query)) return;
      searchedItems.clear();
    } finally {
      if (_isLatestSearch(requestId, query)) {
        isSearchLoading.value = false;
        _applyFilters();
      }
    }
  }

  Future<void> _performLoadRecentSearches() async {
    final preferences = ensureLocalPreferenceRepository();
    final values = await preferences.getStringList(_marketRecentSearchesKey) ??
        const <String>[];
    final next = values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (_sameStringList(recentSearches, next)) {
      return;
    }
    recentSearches.assignAll(next);
  }

  Future<void> _performStoreRecentSearch(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    final normalizedSearchKey = normalizeSearchText(normalized);
    final next = <String>[
      normalized,
      ...recentSearches.where(
        (item) => normalizeSearchText(item) != normalizedSearchKey,
      ),
    ];
    if (next.length > 12) {
      next.removeRange(12, next.length);
    }
    if (!_sameStringList(recentSearches, next)) {
      recentSearches.assignAll(next);
    }
    final preferences = ensureLocalPreferenceRepository();
    await preferences.setStringList(_marketRecentSearchesKey, next);
  }

  Future<void> _performLoadAllCityOptions() async {
    try {
      final next = await _cityDirectoryService.getSortedCities();
      if (_sameStringList(allCityOptions, next)) {
        return;
      }
      allCityOptions.assignAll(next);
    } catch (_) {
      final fallback = <String>{...availableCities}.toList(growable: true);
      sortTurkishStrings(fallback);
      if (_sameStringList(allCityOptions, fallback)) {
        return;
      }
      allCityOptions.assignAll(fallback);
    }
  }

  bool _performIsLatestSearch(int requestId, String query) {
    return requestId == _searchRequestId && searchQuery.value.trim() == query;
  }

  bool _performMatchesLocalQuery(MarketItemModel item, String query) {
    final haystack = <String>[
      item.title,
      item.description,
      item.locationText,
      item.city,
      item.district,
      item.categoryLabel,
      item.categoryPath.join(' '),
      item.sellerName,
      item.attributes.values.map((value) => value.toString()).join(' '),
    ].join(' ');
    final normalizedHaystack = normalizeSearchText(haystack);
    return normalizedHaystack.contains(query);
  }

  int _performCompareItems(MarketItemModel a, MarketItemModel b) {
    switch (sortSelection.value) {
      case 'price_asc':
        return a.price.compareTo(b.price);
      case 'price_desc':
        return b.price.compareTo(a.price);
      default:
        final aTs = a.createdAt;
        final bTs = b.createdAt;
        return bTs.compareTo(aTs);
    }
  }
}
