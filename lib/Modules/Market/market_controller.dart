import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/market_offer_service.dart';
import 'package:turqappv2/Core/Services/market_saved_store.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/market_offer_model.dart';
import 'package:turqappv2/Modules/Market/market_category_sheet.dart';
import 'package:turqappv2/Modules/Market/market_create_view.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Modules/Market/market_my_items_view.dart';
import 'package:turqappv2/Modules/Market/market_offers_view.dart';
import 'package:turqappv2/Modules/Market/market_saved_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'market_schema_service.dart';

class MarketController extends GetxController {
  static const List<String> _preferredCategoryOrder = <String>[
    'Emlak',
    'Telefon',
    'Elektronik',
    'Ev & Yaşam',
    'Motosiklet',
    'Giyim',
    'Kişisel Bakım',
    'Anne & Bebek',
    'Hobi',
    'Ofis',
    'Spor',
  ];

  final MarketSchemaService _schemaService = MarketSchemaService.ensure();
  final MarketRepository _repository = MarketRepository.ensure();

  final ScrollController scrollController = ScrollController();
  final TextEditingController search = TextEditingController();

  final RxDouble scrollOffset = 0.0.obs;
  final RxInt listingSelection = 1.obs;
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
  final RxList<MarketItemModel> pendingCreatedItems = <MarketItemModel>[].obs;
  final RxList<String> savedItemIds = <String>[].obs;
  final RxMap<String, int> roundMenuBadges = <String, int>{}.obs;
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

  Future<void> loadHomeData({bool forceRefresh = false}) async {
    isLoading.value = true;
    try {
      await _schemaService.loadSchema();
      final loadedCategories =
          _schemaService.categories().toList(growable: true)
            ..sort(
              (a, b) => _compareCategoryPriority(
                (a['label'] ?? '').toString(),
                (b['label'] ?? '').toString(),
              ),
            );
      categories.assignAll(loadedCategories);
      roundMenuItems.assignAll(_schemaService.roundMenuItems());
      await _loadListingFromTypesense();
      await _loadSavedItems();
      await _loadRoundMenuBadges(forceRefresh: forceRefresh);
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

  int _compareCategoryPriority(String left, String right) {
    final leftIndex = _preferredCategoryIndex(left);
    final rightIndex = _preferredCategoryIndex(right);
    if (leftIndex != rightIndex) {
      return leftIndex.compareTo(rightIndex);
    }
    return compareTurkishStrings(left, right);
  }

  int _preferredCategoryIndex(String label) {
    final normalized = _categoryOrderKey(label);
    for (var i = 0; i < _preferredCategoryOrder.length; i++) {
      if (_categoryOrderKey(_preferredCategoryOrder[i]) == normalized) {
        return i;
      }
    }
    return _preferredCategoryOrder.length + 100;
  }

  String _categoryOrderKey(String value) {
    final normalized = _normalizeCategoryLabel(value);
    switch (normalized) {
      case 'kozmetik':
        return _normalizeCategoryLabel('Kişisel Bakım');
      default:
        return normalized;
    }
  }

  String _normalizeCategoryLabel(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', 've')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
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
    unawaited(_reloadListingForCurrentFilters());
  }

  Future<void> openItem(MarketItemModel item) async {
    await Get.to(() => MarketDetailView(item: item));
    await loadHomeData(forceRefresh: true);
  }

  List<String> get availableCities {
    final out = <String>{};
    for (final item in items) {
      final city = item.city.trim();
      if (city.isNotEmpty) out.add(city);
    }
    final list = out.toList();
    sortTurkishStrings(list);
    return list;
  }

  bool get hasAdvancedFilters =>
      selectedCityFilter.value.isNotEmpty ||
      selectedContactFilter.value.isNotEmpty ||
      minPriceFilter.value.trim().isNotEmpty ||
      maxPriceFilter.value.trim().isNotEmpty ||
      sortSelection.value != 'newest';

  bool isSaved(String itemId) => savedItemIds.contains(itemId);

  Future<void> toggleSaved(
    MarketItemModel item, {
    bool showSnackbar = true,
  }) async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      AppSnackbar('Giriş Gerekli', 'Kaydetmek için giriş yapmalısın.');
      return;
    }
    final currentlySaved = isSaved(item.id);
    if (currentlySaved) {
      savedItemIds.remove(item.id);
      _applyLocalFavoriteDelta(item.id, -1);
    } else {
      savedItemIds.add(item.id);
      _applyLocalFavoriteDelta(item.id, 1);
    }
    try {
      if (currentlySaved) {
        await MarketSavedStore.unsave(uid, item.id);
      } else {
        await MarketSavedStore.save(uid, item.id);
      }
      if (showSnackbar) {
        AppSnackbar(
          'Tamam',
          currentlySaved ? 'Kayıt kaldırıldı.' : 'İlan kaydedildi.',
        );
      }
    } catch (e) {
      if (currentlySaved) {
        savedItemIds.add(item.id);
        _applyLocalFavoriteDelta(item.id, 1);
      } else {
        savedItemIds.remove(item.id);
        _applyLocalFavoriteDelta(item.id, -1);
      }
      if (showSnackbar) {
        AppSnackbar('Hata', 'Kaydetme işlemi tamamlanamadı.');
      }
    }
  }

  Future<void> openRoundMenu(String key) async {
    switch (key) {
      case 'create':
        final result = await Get.to(() => const MarketCreateView());
        if (result != null) {
          if (result is Map) {
            final item = MarketItemModel.fromJson(
              Map<String, dynamic>.from(result),
            );
            _upsertVisibleItem(item);
            _applyFilters();
            Future.delayed(const Duration(seconds: 2), () {
              unawaited(loadHomeData(forceRefresh: true));
            });
          } else {
            await loadHomeData(forceRefresh: true);
          }
        }
        return;
      case 'my_items':
        await Get.to(() => const MarketMyItemsView());
        await loadHomeData(forceRefresh: true);
        return;
      case 'saved':
        await Get.to(() => const MarketSavedView());
        await loadHomeData(forceRefresh: true);
        return;
      case 'offers':
        await Get.to(() => const MarketOffersView());
        await loadHomeData(forceRefresh: true);
        return;
      case 'categories':
        Get.bottomSheet(
          MarketCategorySheet(controller: this),
          backgroundColor: Colors.white,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        );
        return;
      case 'nearby':
        unawaited(focusNearbyItems());
        return;
      default:
        showComingSoon(key.isEmpty ? 'Market' : key);
    }
  }

  void showComingSoon(String title) {
    AppSnackbar('Yakında', '$title yakında eklenecek.');
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
    unawaited(_reloadListingForCurrentFilters());
  }

  Future<void> refreshHome() async {
    await loadHomeData(forceRefresh: true);
  }

  Future<void> focusNearbyItems() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppSnackbar(
            'İzin Gerekli', 'Yakınındaki ilanlar için konum izni gerekli.');
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
        AppSnackbar('Konum Bulunamadı', 'Şehir bilgisi alınamadı.');
        return;
      }

      if (!availableCities.contains(city)) {
        AppSnackbar('Sınırlı Sonuç', '$city için ilan bulunamadı.');
        return;
      }

      selectedCityFilter.value = city;
      refreshFilters();
      AppSnackbar('Hazır', '$city için yakınındaki ilanlar gösteriliyor.');
    } catch (_) {
      AppSnackbar('Hata', 'Yakınındaki ilanlar yüklenemedi.');
    }
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
      final fetched = await TypesenseMarketSearchService.instance.searchItems(
        query: query,
        limit: 40,
        categoryKey: selectedCategoryKey.value.isEmpty
            ? null
            : selectedCategoryKey.value,
        city:
            selectedCityFilter.value.isEmpty ? null : selectedCityFilter.value,
      );
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

  Future<void> _loadListingFromTypesense() async {
    try {
      final fetched = await TypesenseMarketSearchService.instance.searchItems(
        query: '*',
        limit: 60,
        categoryKey: selectedCategoryKey.value.isEmpty
            ? null
            : selectedCategoryKey.value,
        city:
            selectedCityFilter.value.isEmpty ? null : selectedCityFilter.value,
      );
      final activeFetched = fetched
          .where((item) => item.status == 'active')
          .toList(growable: false);
      items.assignAll(_mergePendingCreatedItems(activeFetched));
    } catch (_) {
      items.assignAll(_mergePendingCreatedItems(const <MarketItemModel>[]));
    }
  }

  Future<void> _reloadListingForCurrentFilters() async {
    isSearchLoading.value = true;
    try {
      await _loadListingFromTypesense();
      _applyFilters();
    } finally {
      isSearchLoading.value = false;
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

  Future<void> _loadRoundMenuBadges({required bool forceRefresh}) async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      roundMenuBadges.assignAll(const <String, int>{});
      return;
    }

    try {
      final ownerFuture = _repository.fetchByOwner(
        uid,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      final sentFuture = MarketOfferService.fetchSentOffers(uid);
      final receivedFuture = MarketOfferService.fetchReceivedOffers(uid);
      final results = await Future.wait<dynamic>([
        ownerFuture,
        sentFuture,
        receivedFuture,
      ]);

      final ownerItems = (results[0] as List<MarketItemModel>)
          .where((item) => item.status != 'archived')
          .length;
      final sentOffers = results[1] as List<MarketOfferModel>;
      final receivedOffers = results[2] as List<MarketOfferModel>;
      final totalOffers = sentOffers.length + receivedOffers.length;

      roundMenuBadges.assignAll(<String, int>{
        'my_items': ownerItems,
        'saved': savedItemIds.length,
        'offers': totalOffers,
      });
    } catch (_) {
      roundMenuBadges.assignAll(<String, int>{
        'my_items': roundMenuBadges['my_items'] ?? 0,
        'saved': savedItemIds.length,
        'offers': roundMenuBadges['offers'] ?? 0,
      });
    }
  }

  void _applyLocalFavoriteDelta(String itemId, int delta) {
    if (delta == 0) return;
    items.assignAll(_updateFavoriteCount(items, itemId, delta));
    searchedItems.assignAll(_updateFavoriteCount(searchedItems, itemId, delta));
    _applyFilters();
  }

  List<MarketItemModel> _updateFavoriteCount(
    List<MarketItemModel> source,
    String itemId,
    int delta,
  ) {
    return source.map((item) {
      if (item.id != itemId) return item;
      final nextCount = item.favoriteCount + delta;
      return item.copyWith(
        favoriteCount: nextCount < 0 ? 0 : nextCount,
      );
    }).toList(growable: false);
  }

  void _upsertVisibleItem(MarketItemModel item) {
    if (item.status != 'active') return;
    final next = <MarketItemModel>[item];
    next.addAll(items.where((existing) => existing.id != item.id));
    items.assignAll(next);
    pendingCreatedItems.removeWhere((existing) => existing.id == item.id);
    pendingCreatedItems.insert(0, item);
  }

  List<MarketItemModel> _mergePendingCreatedItems(
      List<MarketItemModel> source) {
    if (pendingCreatedItems.isEmpty) return source;
    final merged = <MarketItemModel>[];
    final seenIds = <String>{};
    final sourceIds = <String>{};

    for (final item in source) {
      merged.add(item);
      seenIds.add(item.id);
      sourceIds.add(item.id);
    }

    for (final pending in pendingCreatedItems) {
      if (pending.status != 'active') continue;
      if (!seenIds.add(pending.id)) continue;
      merged.insert(0, pending);
    }

    pendingCreatedItems
        .removeWhere((pending) => sourceIds.contains(pending.id));
    return merged;
  }

  String get _currentUid {
    if (CurrentUserService.instance.userId.isNotEmpty) {
      return CurrentUserService.instance.userId;
    }
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }
}
