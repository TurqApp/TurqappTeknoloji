part of 'market_repository_library.dart';

class _TimedMarketItems {
  _TimedMarketItems({
    required this.items,
    required this.cachedAt,
  });

  final List<MarketItemModel> items;
  final DateTime cachedAt;
}
