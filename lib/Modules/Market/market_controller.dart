import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/market_saved_store.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_create_view.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Modules/Market/market_my_items_view.dart';
import 'package:turqappv2/Modules/Market/market_offers_view.dart';
import 'package:turqappv2/Modules/Market/market_saved_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'market_schema_service.dart';

class MarketController extends GetxController {
  final MarketSchemaService _schemaService = MarketSchemaService.ensure();
  final MarketRepository _repository = MarketRepository.ensure();

  final ScrollController scrollController = ScrollController();
  final TextEditingController search = TextEditingController();

  final RxDouble scrollOffset = 0.0.obs;
  final RxInt listingSelection = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearchLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategoryKey = ''.obs;
  final RxString selectedCityFilter = ''.obs;
  final RxString selectedContactFilter = ''.obs;
  final RxString sortSelection = 'newest'.obs;
  final RxString minPriceFilter = ''.obs;
  final RxString maxPriceFilter = ''.obs;
  final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> roundMenuItems =
      <Map<String, dynamic>>[].obs;
  final RxList<MarketItemModel> items = <MarketItemModel>[].obs;
  final RxList<MarketItemModel> searchedItems = <MarketItemModel>[].obs;
  final RxList<MarketItemModel> visibleItems = <MarketItemModel>[].obs;
  final RxList<String> savedItemIds = <String>[].obs;
  Timer? _searchDebounce;
  int _searchRequestId = 0;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    unawaited(loadHomeData());
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    search.dispose();
    super.onClose();
  }

  Future<void> loadHomeData() async {
    isLoading.value = true;
    try {
      await _schemaService.loadSchema();
      categories.assignAll(_schemaService.categories());
      roundMenuItems.assignAll(_schemaService.roundMenuItems());
      final fetchedItems = await _repository.fetchLatestItems(limit: 24);
      items.assignAll(
        fetchedItems.isEmpty ? _repository.sampleItems() : fetchedItems,
      );
      await _loadSavedItems();
      _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  void setSearchQuery(String value) {
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
    } else {
      _searchRequestId++;
      isSearchLoading.value = false;
      searchedItems.clear();
      _applyFilters();
    }
  }

  void toggleListingSelection() {
    listingSelection.value = listingSelection.value == 0 ? 1 : 0;
  }

  void selectCategory(String key) {
    final normalized = key.trim();
    selectedCategoryKey.value =
        selectedCategoryKey.value == normalized ? '' : normalized;
    if (searchQuery.value.trim().length >= 2) {
      setSearchQuery(searchQuery.value);
      return;
    }
    _applyFilters();
  }

  void openItem(MarketItemModel item) {
    Get.to(() => MarketDetailView(item: item));
  }

  List<String> get availableCities {
    final out = <String>{};
    for (final item in items) {
      final city = item.city.trim();
      if (city.isNotEmpty) out.add(city);
    }
    final list = out.toList()..sort();
    return list;
  }

  bool get hasAdvancedFilters =>
      selectedCityFilter.value.isNotEmpty ||
      selectedContactFilter.value.isNotEmpty ||
      minPriceFilter.value.trim().isNotEmpty ||
      maxPriceFilter.value.trim().isNotEmpty ||
      sortSelection.value != 'newest';

  bool isSaved(String itemId) => savedItemIds.contains(itemId);

  Future<void> toggleSaved(MarketItemModel item) async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      AppSnackbar('Giris Gerekli', 'Kaydetmek icin giris yapmalisin.');
      return;
    }
    final currentlySaved = isSaved(item.id);
    if (currentlySaved) {
      savedItemIds.remove(item.id);
    } else {
      savedItemIds.add(item.id);
    }
    try {
      if (currentlySaved) {
        await MarketSavedStore.unsave(uid, item.id);
      } else {
        await MarketSavedStore.save(uid, item.id);
      }
      AppSnackbar(
        'Tamam',
        currentlySaved ? 'Kayit kaldirildi.' : 'Ilan kaydedildi.',
      );
    } catch (e) {
      if (currentlySaved) {
        savedItemIds.add(item.id);
      } else {
        savedItemIds.remove(item.id);
      }
      AppSnackbar('Hata', 'Kaydetme islemi tamamlanamadi.');
    }
  }

  void openRoundMenu(String key) {
    switch (key) {
      case 'create':
        Get.to(() => MarketCreateView());
        return;
      case 'my_items':
        Get.to(() => MarketMyItemsView());
        return;
      case 'saved':
        Get.to(() => MarketSavedView());
        return;
      case 'offers':
        Get.to(() => MarketOffersView());
        return;
      case 'categories':
        showComingSoon('Kategoriler');
        return;
      case 'nearby':
        showComingSoon('Yakinimdakiler');
        return;
      default:
        showComingSoon(key.isEmpty ? 'Market' : key);
    }
  }

  void showComingSoon(String title) {
    AppSnackbar('Yakinda', '$title yakinda eklenecek.');
  }

  void applyAdvancedFilters({
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

  void clearAdvancedFilters() {
    selectedCityFilter.value = '';
    selectedContactFilter.value = '';
    minPriceFilter.value = '';
    maxPriceFilter.value = '';
    sortSelection.value = 'newest';
    refreshFilters();
  }

  void refreshFilters() {
    if (searchQuery.value.trim().length >= 2) {
      setSearchQuery(searchQuery.value);
      return;
    }
    _applyFilters();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    scrollOffset.value = scrollController.offset;
  }

  void _applyFilters() {
    final query = searchQuery.value.trim().toLowerCase();
    final categoryKey = selectedCategoryKey.value.trim();
    final cityFilter = selectedCityFilter.value.trim().toLowerCase();
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
      final matchesCategory = categoryKey.isEmpty ||
          item.categoryKey == categoryKey ||
          item.categoryKey.startsWith('$categoryKey/');
      if (!matchesCategory) return false;
      if (cityFilter.isNotEmpty && item.city.toLowerCase() != cityFilter) {
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
    visibleItems.assignAll(filtered);
  }

  Future<void> _searchFromTypesense(String query, int requestId) async {
    try {
      final docIds = await TypesenseMarketSearchService.instance.searchDocIds(
        query: query,
        limit: 40,
        categoryKey: selectedCategoryKey.value.isEmpty
            ? null
            : selectedCategoryKey.value,
        city:
            selectedCityFilter.value.isEmpty ? null : selectedCityFilter.value,
      );
      if (!_isLatestSearch(requestId, query)) return;

      final fetched = docIds.isEmpty
          ? const <MarketItemModel>[]
          : await _repository.fetchByIds(docIds);
      if (!_isLatestSearch(requestId, query)) return;

      final results = fetched.where((item) => item.status == 'active').toList(
            growable: false,
          );
      searchedItems.assignAll(
        results.isEmpty ? _searchLocally(query) : results,
      );
    } catch (_) {
      if (!_isLatestSearch(requestId, query)) return;
      searchedItems.assignAll(_searchLocally(query));
    } finally {
      if (_isLatestSearch(requestId, query)) {
        isSearchLoading.value = false;
        _applyFilters();
      }
    }
  }

  bool _isLatestSearch(int requestId, String query) {
    return requestId == _searchRequestId && searchQuery.value.trim() == query;
  }

  List<MarketItemModel> _searchLocally(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const <MarketItemModel>[];
    return items
        .where((item) => _matchesLocalQuery(item, normalized))
        .toList(growable: false);
  }

  bool _matchesLocalQuery(MarketItemModel item, String query) {
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
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  int _compareItems(MarketItemModel a, MarketItemModel b) {
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

  Future<void> _loadSavedItems() async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      savedItemIds.clear();
      return;
    }
    try {
      final ids = await MarketSavedStore.getSavedItemIds(uid);
      savedItemIds.assignAll(ids.toList(growable: false));
    } catch (_) {
      savedItemIds.clear();
    }
  }

  String get _currentUid {
    if (CurrentUserService.instance.userId.isNotEmpty) {
      return CurrentUserService.instance.userId;
    }
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }
}
