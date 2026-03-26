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
