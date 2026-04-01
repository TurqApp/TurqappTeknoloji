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

  Future<List<MarketItemModel>?> _loadOwnerWarmSnapshot(
    MarketOwnerQuery query,
  ) async {
    final normalizedUserId = query.userId.trim();
    if (normalizedUserId.isEmpty) return null;
    final items = await TypesenseMarketSearchService.instance.searchItems(
      query: '*',
      limit: query.effectiveLimit,
      page: 1,
      userId: normalizedUserId,
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

  Future<List<MarketItemModel>> _fetchOwnerItems(MarketOwnerQuery query) async {
    final normalizedUserId = query.userId.trim();
    if (normalizedUserId.isEmpty) return const <MarketItemModel>[];
    final normalizedLimit = query.effectiveLimit;
    const options = GetOptions(source: Source.serverAndCache);
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await FirebaseFirestore.instance
          .collection('marketStore')
          .where('userId', isEqualTo: normalizedUserId)
          .orderBy('createdAt', descending: true)
          .limit(normalizedLimit)
          .get(options);
    } on FirebaseException {
      snapshot = await FirebaseFirestore.instance
          .collection('marketStore')
          .where('userId', isEqualTo: normalizedUserId)
          .limit(normalizedLimit)
          .get(options);
    }
    final items = snapshot.docs
        .map((doc) => MarketItemModel.fromMap(doc.data(), doc.id))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(normalizedLimit).toList(growable: false);
  }
}
