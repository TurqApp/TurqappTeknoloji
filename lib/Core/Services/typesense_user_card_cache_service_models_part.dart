part of 'typesense_user_card_cache_service.dart';

class _CachedUserCardsResult {
  const _CachedUserCardsResult({required this.cards, required this.cachedAt});

  final Map<String, Map<String, dynamic>> cards;
  final DateTime cachedAt;
  bool get isFresh =>
      DateTime.now().difference(cachedAt) < _typesenseUserCardCacheTtl;
}
