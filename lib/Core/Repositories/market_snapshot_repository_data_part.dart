part of 'market_snapshot_repository.dart';

extension _MarketSnapshotRepositoryDataX on MarketSnapshotRepository {
  Future<List<MarketItemModel>> _fetchItems(MarketListingQuery query) {
    return TypesenseMarketSearchService.instance.searchItems(
      query: query.query,
      limit: query.limit,
      page: query.page,
      preferCache: true,
    );
  }

  Future<List<MarketItemModel>?> _loadWarmSnapshot(
    MarketListingQuery query,
  ) async {
    final items = await TypesenseMarketSearchService.instance.searchItems(
      query: query.query,
      limit: query.limit,
      page: query.page,
      preferCache: true,
      cacheOnly: true,
    );
    return items.isEmpty ? null : items;
  }

  Map<String, dynamic> _encodeItems(List<MarketItemModel> items) {
    return <String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
  }

  List<MarketItemModel> _decodeItems(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map((raw) => MarketItemModel.fromJson(Map<String, dynamic>.from(raw)))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}
