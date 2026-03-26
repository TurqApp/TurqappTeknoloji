part of 'typesense_user_card_cache_service.dart';

class TypesenseUserCardCacheService extends GetxService {
  static const Duration _ttl = Duration(minutes: 15);
  static const String _prefsPrefix = 'typesense_user_cards_v1';

  final Map<String, _CachedUserCardsResult> _memory =
      <String, _CachedUserCardsResult>{};
  SharedPreferences? _prefs;

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
