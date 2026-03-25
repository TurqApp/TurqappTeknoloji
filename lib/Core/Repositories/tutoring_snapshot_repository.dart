import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

part 'tutoring_snapshot_repository_data_part.dart';

class TutoringSnapshotRepository extends GetxService {
  TutoringSnapshotRepository();

  static const String _homeSurfaceKey = 'tutoring_home_snapshot';
  static const String _searchSurfaceKey = 'tutoring_search_snapshot';

  static TutoringSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<TutoringSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<TutoringSnapshotRepository>();
  }

  static TutoringSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TutoringSnapshotRepository(), permanent: true);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  late final CacheFirstCoordinator<List<TutoringModel>> _coordinator =
      CacheFirstCoordinator<List<TutoringModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<TutoringModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<TutoringModel>>(
      prefsPrefix: 'tutoring_snapshot_v1',
      encode: _encodeTutoringSnapshots,
      decode: _decodeTutoringSnapshots,
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
    resolve: (raw) => _resolveTutoringHits(this, raw.hits),
    loadWarmSnapshot: _loadWarmTutoringSnapshot,
    isEmpty: (items) => items.isEmpty,
  );

  late final EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
      _searchAdapter = EducationTypesenseCacheFirstAdapter<List<TutoringModel>>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    resolve: (raw) => _resolveTutoringHits(this, raw.hits),
    loadWarmSnapshot: _loadWarmTutoringSnapshot,
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
}
