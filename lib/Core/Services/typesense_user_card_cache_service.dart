import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/typesense_user_service.dart';

part 'typesense_user_card_cache_service_models_part.dart';
part 'typesense_user_card_cache_service_cache_part.dart';

class TypesenseUserCardCacheService extends GetxService {
  static const Duration _ttl = Duration(minutes: 15);
  static const String _prefsPrefix = 'typesense_user_cards_v1';

  final Map<String, _CachedUserCardsResult> _memory =
      <String, _CachedUserCardsResult>{};
  SharedPreferences? _prefs;

  static TypesenseUserCardCacheService? maybeFind() {
    final isRegistered = Get.isRegistered<TypesenseUserCardCacheService>();
    if (!isRegistered) return null;
    return Get.find<TypesenseUserCardCacheService>();
  }

  static TypesenseUserCardCacheService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TypesenseUserCardCacheService(), permanent: true);
  }

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
