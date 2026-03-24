import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_constants.dart';

part 'scholarship_snapshot_repository_query_part.dart';
part 'scholarship_snapshot_repository_codec_part.dart';

class ScholarshipListingSnapshot {
  const ScholarshipListingSnapshot({
    required this.items,
    required this.found,
  });

  final List<Map<String, dynamic>> items;
  final int found;
}

class ScholarshipSnapshotRepository extends GetxService {
  ScholarshipSnapshotRepository();

  static const String _homeSurfaceKey = 'scholarship_home_snapshot';
  static const String _searchSurfaceKey = 'scholarship_search_snapshot';

  static ScholarshipSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ScholarshipSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<ScholarshipSnapshotRepository>();
  }

  static ScholarshipSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ScholarshipSnapshotRepository(), permanent: true);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  late final CacheFirstCoordinator<ScholarshipListingSnapshot> _coordinator =
      CacheFirstCoordinator<ScholarshipListingSnapshot>(
    memoryStore: MemoryScopedSnapshotStore<ScholarshipListingSnapshot>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<ScholarshipListingSnapshot>(
      prefsPrefix: 'scholarship_snapshot_v1',
      encode: _encodeSnapshot,
      decode: _decodeSnapshot,
    ),
    telemetry: const CacheFirstKpiTelemetry<ScholarshipListingSnapshot>(),
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

  late final EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>
      _homeAdapter =
      EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    resolve: _resolveHits,
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (snapshot) => snapshot.items.isEmpty,
  );

  late final EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>
      _searchAdapter =
      EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    resolve: _resolveHits,
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (snapshot) => snapshot.items.isEmpty,
  );

  Stream<CachedResource<ScholarshipListingSnapshot>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.scholarshipHomeInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) =>
      _openHomeImpl(
        userId: userId,
        limit: limit,
        page: page,
        forceSync: forceSync,
      );

  Future<CachedResource<ScholarshipListingSnapshot>> loadHome({
    required String userId,
    int limit = ReadBudgetRegistry.scholarshipHomeInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) =>
      _loadHomeImpl(
        userId: userId,
        limit: limit,
        page: page,
        forceSync: forceSync,
      );

  Stream<CachedResource<ScholarshipListingSnapshot>> openSearch({
    required String query,
    required String userId,
    int limit = 40,
    int page = 1,
    bool forceSync = false,
  }) =>
      _openSearchImpl(
        query: query,
        userId: userId,
        limit: limit,
        page: page,
        forceSync: forceSync,
      );

  Future<CachedResource<ScholarshipListingSnapshot>> search({
    required String query,
    required String userId,
    int limit = 40,
    int page = 1,
    bool forceSync = false,
  }) =>
      _searchImpl(
        query: query,
        userId: userId,
        limit: limit,
        page: page,
        forceSync: forceSync,
      );
}
