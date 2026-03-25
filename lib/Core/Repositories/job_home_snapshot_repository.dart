import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/job_model.dart';

part 'job_home_snapshot_repository_data_part.dart';

class JobHomeSnapshotRepository extends GetxService {
  JobHomeSnapshotRepository();

  static const String _homeSurfaceKey = 'jobs_home_snapshot';
  static const String _searchSurfaceKey = 'jobs_search_snapshot';

  static JobHomeSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<JobHomeSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<JobHomeSnapshotRepository>();
  }

  static JobHomeSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(JobHomeSnapshotRepository(), permanent: true);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  late final CacheFirstCoordinator<List<JobModel>> _coordinator =
      CacheFirstCoordinator<List<JobModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<JobModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<JobModel>>(
      prefsPrefix: 'job_home_snapshot_v1',
      encode: _encodeJobs,
      decode: _decodeJobs,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<JobModel>>(),
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

  late final EducationTypesenseCacheFirstAdapter<List<JobModel>> _homeAdapter =
      EducationTypesenseCacheFirstAdapter<List<JobModel>>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    resolve: (raw) => _resolveHits(raw.hits),
    loadWarmSnapshot: _loadWarmEducationSnapshot,
    isEmpty: (jobs) => jobs.isEmpty,
  );

  late final EducationTypesenseCacheFirstAdapter<List<JobModel>>
      _searchAdapter = EducationTypesenseCacheFirstAdapter<List<JobModel>>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    resolve: (raw) => _resolveHits(raw.hits),
    loadWarmSnapshot: _loadWarmEducationSnapshot,
    isEmpty: (jobs) => jobs.isEmpty,
  );

  Stream<CachedResource<List<JobModel>>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.jobHomeInitialLimit,
    bool forceSync = false,
  }) {
    return _homeAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.job,
        query: '*',
        limit: limit,
        userId: userId,
        scopeTag: 'home',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<JobModel>>> loadHome({
    required String userId,
    int limit = ReadBudgetRegistry.jobHomeInitialLimit,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<JobModel>>> openSearch({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) {
    return _searchAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.job,
        query: query,
        limit: limit,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<JobModel>>> search({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) {
    return openSearch(
      query: query,
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }
}
