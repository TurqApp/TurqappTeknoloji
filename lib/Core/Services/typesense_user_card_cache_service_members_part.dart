part of 'typesense_user_card_cache_service.dart';

const Duration _typesenseUserCardCacheTtl = Duration(minutes: 15);
const String _typesenseUserCardPrefsPrefix = 'typesense_user_cards_v1';
const int _typesenseUserCardMemoryEntryLimit = 128;
const int _typesenseUserCardPrefsEntryLimit = 256;

class TypesenseUserCardCacheService extends GetxService {
  final LinkedHashMap<String, _CachedUserCardsResult> _memory =
      LinkedHashMap<String, _CachedUserCardsResult>();
  final Map<String, Future<Map<String, Map<String, dynamic>>>> _inFlight =
      <String, Future<Map<String, Map<String, dynamic>>>>{};
  SharedPreferences? _prefs;
}
