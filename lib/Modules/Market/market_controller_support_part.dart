part of 'market_controller.dart';

const String _marketRecentSearchesKey = 'market_recent_searches_v1';
const String _marketListingSelectionPrefKeyPrefix =
    'pasaj_market_listing_selection';
const List<String> _marketPreferredCategoryOrder = <String>[
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

extension MarketControllerSupportPart on MarketController {
  List<String> get availableCities => _computeAvailableCities();

  bool get hasAdvancedFilters => _computeHasAdvancedFilters();

  Future<void> _restoreListingSelection() => _performRestoreListingSelection();

  Future<void> _persistListingSelection() => _performPersistListingSelection();

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

  List<String> _computeAvailableCities() {
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

  bool _computeHasAdvancedFilters() {
    return selectedCityFilter.value.isNotEmpty ||
        selectedContactFilter.value.isNotEmpty ||
        minPriceFilter.value.trim().isNotEmpty ||
        maxPriceFilter.value.trim().isNotEmpty ||
        sortSelection.value != 'newest';
  }
}
