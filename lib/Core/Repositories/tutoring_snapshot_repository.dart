import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

class TutoringSnapshotRepository extends GetxService {
  TutoringSnapshotRepository();

  static const String _homeSurfaceKey = 'tutoring_home_snapshot';
  static const String _searchSurfaceKey = 'tutoring_search_snapshot';

  static TutoringSnapshotRepository _ensureService() {
    if (Get.isRegistered<TutoringSnapshotRepository>()) {
      return Get.find<TutoringSnapshotRepository>();
    }
    return Get.put(TutoringSnapshotRepository(), permanent: true);
  }

  static TutoringSnapshotRepository ensure() {
    return _ensureService();
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  late final CacheFirstCoordinator<List<TutoringModel>> _coordinator =
      CacheFirstCoordinator<List<TutoringModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<TutoringModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<TutoringModel>>(
      prefsPrefix: 'tutoring_snapshot_v1',
      encode: _encodeTutorings,
      decode: _decodeTutorings,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<TutoringModel>>(),
    policy: const CacheFirstPolicy(
      snapshotTtl: Duration(minutes: 20),
      minLiveSyncInterval: Duration(seconds: 30),
      syncOnOpen: true,
      allowWarmLaunchFallback: true,
      persistWarmLaunchSnapshot: true,
      treatWarmLaunchAsStale: true,
      preservePreviousOnEmptyLive: true,
    ),
  );

  late final EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
      _homeAdapter = EducationTypesenseCacheFirstAdapter<List<TutoringModel>>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    resolve: (raw) => _resolveHits(raw.hits),
    loadWarmSnapshot: _loadWarmEducationSnapshot,
    isEmpty: (items) => items.isEmpty,
  );

  late final EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
      _searchAdapter = EducationTypesenseCacheFirstAdapter<List<TutoringModel>>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    resolve: (raw) => _resolveHits(raw.hits),
    loadWarmSnapshot: _loadWarmEducationSnapshot,
    isEmpty: (items) => items.isEmpty,
  );

  Stream<CachedResource<List<TutoringModel>>> openHome({
    required String userId,
    int limit = 30,
    int page = 1,
    bool forceSync = false,
  }) {
    return _homeAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.tutoring,
        query: '*',
        limit: limit,
        page: page,
        userId: userId,
        scopeTag: page <= 1 ? 'home' : 'home_page_$page',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TutoringModel>>> loadHome({
    required String userId,
    int limit = 30,
    int page = 1,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      page: page,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<TutoringModel>>> openSearch({
    required String userId,
    required String query,
    int limit = 40,
    bool forceSync = false,
  }) {
    return _searchAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.tutoring,
        query: query,
        limit: limit,
        page: 1,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TutoringModel>>> search({
    required String userId,
    required String query,
    int limit = 40,
    bool forceSync = false,
  }) {
    return openSearch(
      userId: userId,
      query: query,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Future<List<TutoringModel>?> _loadWarmEducationSnapshot(
    EducationTypesenseQuery query,
  ) async {
    final raw = await TypesenseEducationSearchService.instance.searchHits(
      entity: query.entity,
      query: query.query,
      limit: query.limit,
      page: query.page,
      filterBy: query.filterBy,
      sortBy: query.sortBy,
      cacheOnly: true,
    );
    final items = _resolveHits(raw.hits);
    return items.isEmpty ? null : items;
  }

  List<TutoringModel> _resolveHits(List<Map<String, dynamic>> hits) {
    return hits
        .map(TutoringModel.fromTypesenseHit)
        .where((item) => item.docID.isNotEmpty)
        .where((item) => item.ended != true)
        .map((item) {
      _primeUserSummary(item);
      return item;
    }).toList(growable: false);
  }

  void _primeUserSummary(TutoringModel item) {
    final userId = item.userID.trim();
    if (userId.isEmpty) return;
    final summary = _userSummaryResolver.resolveFromMaps(
      userId,
      embedded: <String, dynamic>{
        'nickname': item.nickname,
        'displayName': item.displayName,
        'avatarUrl': item.avatarUrl,
        'rozet': item.rozet,
      },
    );
    unawaited(_userSummaryResolver.seedRaw(userId, summary.toMap()));
  }

  Map<String, dynamic> _encodeTutorings(List<TutoringModel> items) {
    return <String, dynamic>{
      'items': items
          .map((item) => <String, dynamic>{
                'docID': item.docID,
                ...item.toJson(),
              })
          .toList(growable: false),
    };
  }

  List<TutoringModel> _decodeTutorings(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
          final docId = (item.remove('docID') ?? '').toString();
          return TutoringModel.fromJson(item, docId);
        })
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
  }
}
