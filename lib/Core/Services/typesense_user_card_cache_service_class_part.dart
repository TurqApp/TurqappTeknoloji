part of 'typesense_user_card_cache_service.dart';

class TypesenseUserCardCacheService extends GetxService
    with _TypesenseUserCardCacheServiceMembersPart {
  static const Duration _ttl = Duration(minutes: 15);
  static const String _prefsPrefix = 'typesense_user_cards_v1';

  Future<Map<String, Map<String, dynamic>>> getUserCardsByIds(
    List<String> ids, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _TypesenseUserCardCacheServiceCachePart(this).getUserCardsByIds(
        ids,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<void> invalidateAll() =>
      _TypesenseUserCardCacheServiceCachePart(this).invalidateAll();
}
