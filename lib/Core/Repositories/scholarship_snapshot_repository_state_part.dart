part of 'scholarship_snapshot_repository.dart';

class _ScholarshipSnapshotRepositoryState {
  final userSummaryResolver = UserSummaryResolver.ensure();
  CacheFirstCoordinator<ScholarshipListingSnapshot>? coordinator;
  EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>? homeAdapter;
  EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>?
      searchAdapter;
}

extension ScholarshipSnapshotRepositoryStatePart
    on ScholarshipSnapshotRepository {
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;

  CacheFirstCoordinator<ScholarshipListingSnapshot> get _coordinator =>
      _state.coordinator ??= _createScholarshipSnapshotCoordinator(this);

  EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>
      get _homeAdapter =>
          _state.homeAdapter ??= _createScholarshipSnapshotHomeAdapter(this);

  EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>
      get _searchAdapter => _state.searchAdapter ??=
          _createScholarshipSnapshotSearchAdapter(this);
}

CacheFirstCoordinator<ScholarshipListingSnapshot>
    _createScholarshipSnapshotCoordinator(
  ScholarshipSnapshotRepository controller,
) {
  return CacheFirstCoordinator<ScholarshipListingSnapshot>(
    memoryStore: MemoryScopedSnapshotStore<ScholarshipListingSnapshot>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<ScholarshipListingSnapshot>(
      prefsPrefix: 'scholarship_snapshot_v1',
      encode: controller._encodeSnapshot,
      decode: controller._decodeSnapshot,
    ),
    telemetry: const CacheFirstKpiTelemetry<ScholarshipListingSnapshot>(),
    policy: CacheFirstPolicyRegistry.policyForSurface(
      ScholarshipSnapshotRepository._homeSurfaceKey,
    ),
  );
}

EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>
    _createScholarshipSnapshotHomeAdapter(
  ScholarshipSnapshotRepository controller,
) {
  return EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>(
    surfaceKey: ScholarshipSnapshotRepository._homeSurfaceKey,
    coordinator: controller._coordinator,
    resolve: controller._resolveHits,
    loadWarmSnapshot: controller._loadWarmSnapshot,
    isEmpty: (snapshot) => snapshot.items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      ScholarshipSnapshotRepository._homeSurfaceKey,
    ),
  );
}

EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>
    _createScholarshipSnapshotSearchAdapter(
  ScholarshipSnapshotRepository controller,
) {
  return EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>(
    surfaceKey: ScholarshipSnapshotRepository._searchSurfaceKey,
    coordinator: controller._coordinator,
    resolve: controller._resolveHits,
    loadWarmSnapshot: controller._loadWarmSnapshot,
    isEmpty: (snapshot) => snapshot.items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      ScholarshipSnapshotRepository._searchSurfaceKey,
    ),
  );
}
