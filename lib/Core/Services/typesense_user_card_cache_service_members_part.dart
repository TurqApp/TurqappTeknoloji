part of 'typesense_user_card_cache_service.dart';

mixin _TypesenseUserCardCacheServiceMembersPart on GetxService {
  final Map<String, _CachedUserCardsResult> _memory =
      <String, _CachedUserCardsResult>{};
  SharedPreferences? _prefs;
}
