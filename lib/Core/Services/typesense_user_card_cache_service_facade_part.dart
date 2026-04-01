part of 'typesense_user_card_cache_service.dart';

TypesenseUserCardCacheService? maybeFindTypesenseUserCardCacheService() {
  final isRegistered = Get.isRegistered<TypesenseUserCardCacheService>();
  if (!isRegistered) return null;
  return Get.find<TypesenseUserCardCacheService>();
}

TypesenseUserCardCacheService ensureTypesenseUserCardCacheService() {
  final existing = maybeFindTypesenseUserCardCacheService();
  if (existing != null) return existing;
  return Get.put(TypesenseUserCardCacheService(), permanent: true);
}

extension TypesenseUserCardCacheServiceFacadePart
    on TypesenseUserCardCacheService {
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
