import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/market_item_model.dart';

part 'typesense_market_service_cache_part.dart';
part 'typesense_market_service_search_part.dart';

class _CachedMarketSearchResult {
  const _CachedMarketSearchResult({
    required this.items,
    required this.cachedAt,
  });

  final List<MarketItemModel> items;
  final DateTime cachedAt;
}

class TypesenseMarketSearchService {
  TypesenseMarketSearchService._();

  static TypesenseMarketSearchService? _instance;
  static TypesenseMarketSearchService? maybeFind() => _instance;

  static TypesenseMarketSearchService ensure() =>
      maybeFind() ?? (_instance = TypesenseMarketSearchService._());

  static TypesenseMarketSearchService get instance => ensure();
  static const Duration _ttl = Duration(minutes: 15);
  static const String _prefsPrefix = 'typesense_market_search_v1';

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final Map<String, _CachedMarketSearchResult> _memory =
      <String, _CachedMarketSearchResult>{};
  SharedPreferences? _prefs;

  Future<List<MarketItemModel>> searchItems({
    required String query,
    int limit = 30,
    int page = 1,
    String? docId,
    String? userId,
    String? categoryKey,
    String? city,
    String? district,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _performSearchItems(
        query: query,
        limit: limit,
        page: page,
        docId: docId,
        userId: userId,
        categoryKey: categoryKey,
        city: city,
        district: district,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<MarketItemModel?> fetchByDocId(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _performFetchByDocId(
        docId,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<List<MarketItemModel>> fetchByDocIds(
    List<String> docIds, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) =>
      _performFetchByDocIds(
        docIds,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
      );

  Future<List<MarketItemModel>> fetchByUserId(
    String userId, {
    int limit = 60,
    bool preferCache = true,
    bool forceRefresh = false,
  }) =>
      _performFetchByUserId(
        userId,
        limit: limit,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
      );

  Future<void> invalidateAll() => _performInvalidateAll();

  Future<void> invalidateForMutation({
    String? docId,
    String? userId,
  }) =>
      _performInvalidateForMutation(
        docId: docId,
        userId: userId,
      );

  String _searchCacheKey({
    required String query,
    required int limit,
    required int page,
    String? docId,
    String? userId,
    String? categoryKey,
    String? city,
    String? district,
  }) {
    return <String>[
      'q=${query.trim()}',
      'limit=$limit',
      'page=$page',
      'docId=${(docId ?? '').trim()}',
      'userId=${(userId ?? '').trim()}',
      'categoryKey=${(categoryKey ?? '').trim()}',
      'city=${(city ?? '').trim()}',
      'district=${(district ?? '').trim()}',
    ].join('|');
  }

  String _prefsKey(String key) => '$_prefsPrefix:$key';
}
