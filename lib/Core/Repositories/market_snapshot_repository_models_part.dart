part of 'market_snapshot_repository.dart';

class MarketListingQuery {
  const MarketListingQuery({
    required this.query,
    required this.userId,
    this.limit = ReadBudgetRegistry.marketHomeInitialLimit,
    this.page = 1,
    this.scopeTag = '',
  });

  final String query;
  final String userId;
  final int limit;
  final int page;
  final String scopeTag;

  String get scopeId => <String>[
        query.trim(),
        'limit=$limit',
        'page=$page',
        'scope=${scopeTag.trim()}',
      ].join('|');
}
