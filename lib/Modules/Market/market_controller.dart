import 'dart:async';
import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Repositories/market_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/market_offer_service.dart';
import 'package:turqappv2/Core/Services/market_saved_store.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/market_offer_model.dart';
import 'package:turqappv2/Modules/Market/market_category_utils.dart';
import 'package:turqappv2/Modules/Market/market_category_sheet.dart';
import 'package:turqappv2/Modules/Market/market_create_view.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Modules/Market/market_my_items_view.dart';
import 'package:turqappv2/Modules/Market/market_offers_view.dart';
import 'package:turqappv2/Modules/Market/market_saved_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'market_schema_service.dart';

part 'market_controller_filter_part.dart';
part 'market_controller_home_part.dart';
part 'market_controller_actions_part.dart';
part 'market_controller_lifecycle_part.dart';
part 'market_controller_runtime_part.dart';

class MarketController extends GetxController {
  static MarketController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(MarketController(), permanent: permanent);
  }

  static MarketController? maybeFind() {
    final isRegistered = Get.isRegistered<MarketController>();
    if (!isRegistered) return null;
    return Get.find<MarketController>();
  }

  static const String _recentSearchesKey = 'market_recent_searches_v1';
  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_market_listing_selection';
  static const List<String> _preferredCategoryOrder = <String>[
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
  final MarketSnapshotRepository _marketSnapshotRepository =
      MarketSnapshotRepository.ensure();
  final MarketRepository _repository = MarketRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();

  final ScrollController scrollController = ScrollController();
  final TextEditingController search = TextEditingController();

  final RxDouble scrollOffset = 0.0.obs;
  final RxBool listingSelectionReady = false.obs;
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
  final RxList<String> allCityOptions = <String>[].obs;
  final RxList<String> savedItemIds = <String>[].obs;
  final RxMap<String, int> roundMenuBadges = <String, int>{}.obs;
  final RxList<String> recentSearches = <String>[].obs;
  StreamSubscription<CachedResource<List<MarketItemModel>>>? _homeSnapshotSub;
  Timer? _searchDebounce;
  int _searchRequestId = 0;

  bool _sameStringList(Iterable<String> left, Iterable<String> right) {
    return listEquals(
      left.toList(growable: false),
      right.toList(growable: false),
    );
  }

  bool _sameBadgeMap(Map<String, int> left, Map<String, int> right) {
    return mapEquals(left, right);
  }

  bool _sameMapList(
    Iterable<Map<String, dynamic>> left,
    Iterable<Map<String, dynamic>> right,
  ) {
    return listEquals(
      left.map(jsonEncode).toList(growable: false),
      right.map(jsonEncode).toList(growable: false),
    );
  }

  bool _sameMarketList(List<MarketItemModel> next) {
    return _sameMarketEntries(items, next);
  }

  bool _sameMarketEntries(
    List<MarketItemModel> current,
    List<MarketItemModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.id,
            item.title,
            item.price,
            item.favoriteCount,
            item.viewCount,
            item.offerCount,
            item.city,
            item.district,
            item.coverImageUrl,
            item.status,
            item.createdAt,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.id,
            item.title,
            item.price,
            item.favoriteCount,
            item.viewCount,
            item.offerCount,
            item.city,
            item.district,
            item.coverImageUrl,
            item.status,
            item.createdAt,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  bool _sameVisibleItems(List<MarketItemModel> next) {
    return _sameMarketEntries(visibleItems, next);
  }

  Future<void> _restoreListingSelection() => _performRestoreListingSelection();

  Future<void> _persistListingSelection() => _performPersistListingSelection();

  @override
  void onInit() {
    super.onInit();
    _handleLifecycleInit();
  }

  @override
  void onClose() {
    _handleLifecycleClose();
    super.onClose();
  }

  List<String> get availableCities {
    if (allCityOptions.isNotEmpty) {
      return allCityOptions.toList(growable: false);
    }
    final out = <String>{};
    for (final collection in <List<MarketItemModel>>[
      items,
      searchedItems,
      visibleItems,
      pendingCreatedItems,
    ]) {
      for (final item in collection) {
        final city = item.city.trim();
        if (city.isNotEmpty) out.add(city);
      }
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
}
