part of 'typesense_user_card_cache_service.dart';

const Duration _typesenseUserCardCacheTtl = Duration(minutes: 15);
const String _typesenseUserCardPrefsPrefix = 'typesense_user_cards_v1';

class TypesenseUserCardCacheService extends GetxService {
  final Map<String, _CachedUserCardsResult> _memory =
      <String, _CachedUserCardsResult>{};
  final Map<String, Future<Map<String, Map<String, dynamic>>>> _inFlight =
      <String, Future<Map<String, Map<String, dynamic>>>>{};
  SharedPreferences? _prefs;
}
