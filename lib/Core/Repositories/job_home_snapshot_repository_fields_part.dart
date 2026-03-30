part of 'job_home_snapshot_repository.dart';

class _JobHomeSnapshotRepositoryState {
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  late final CacheFirstCoordinator<List<JobModel>> coordinator;
  late final EducationTypesenseCacheFirstAdapter<List<JobModel>> homeAdapter;
  late final EducationTypesenseCacheFirstAdapter<List<JobModel>> searchAdapter;
  late final CacheFirstQueryPipeline<JobOwnerQuery, List<JobModel>,
      List<JobModel>> ownerPipeline;

  void initialize(JobHomeSnapshotRepository repository) {
    final homeSchemaVersion = CacheFirstPolicyRegistry.schemaVersionForSurface(
      JobHomeSnapshotRepository._homeSurfaceKey,
    );
    final searchSchemaVersion =
        CacheFirstPolicyRegistry.schemaVersionForSurface(
      JobHomeSnapshotRepository._searchSurfaceKey,
    );
    final ownerSchemaVersion = CacheFirstPolicyRegistry.schemaVersionForSurface(
      JobHomeSnapshotRepository._ownerSurfaceKey,
    );
    coordinator = CacheFirstCoordinator<List<JobModel>>(
      memoryStore: MemoryScopedSnapshotStore<List<JobModel>>(),
      snapshotStore: SharedPrefsScopedSnapshotStore<List<JobModel>>(
        prefsPrefix: 'job_home_snapshot_v1',
        encode: repository._encodeJobs,
        decode: repository._decodeJobs,
      ),
      telemetry: const CacheFirstKpiTelemetry<List<JobModel>>(),
      policy: CacheFirstPolicyRegistry.policyForSurface(
        JobHomeSnapshotRepository._homeSurfaceKey,
      ),
    );
    homeAdapter = EducationTypesenseCacheFirstAdapter<List<JobModel>>(
      surfaceKey: JobHomeSnapshotRepository._homeSurfaceKey,
      coordinator: coordinator,
      resolve: (raw) => repository._resolveHits(raw.hits),
      loadWarmSnapshot: repository._loadWarmEducationSnapshot,
      isEmpty: (jobs) => jobs.isEmpty,
      schemaVersion: homeSchemaVersion,
    );
    searchAdapter = EducationTypesenseCacheFirstAdapter<List<JobModel>>(
      surfaceKey: JobHomeSnapshotRepository._searchSurfaceKey,
      coordinator: coordinator,
      resolve: (raw) => repository._resolveHits(raw.hits),
      loadWarmSnapshot: repository._loadWarmEducationSnapshot,
      isEmpty: (jobs) => jobs.isEmpty,
      schemaVersion: searchSchemaVersion,
    );
    ownerPipeline =
        CacheFirstQueryPipeline<JobOwnerQuery, List<JobModel>, List<JobModel>>(
      surfaceKey: JobHomeSnapshotRepository._ownerSurfaceKey,
      coordinator: coordinator,
      userIdResolver: (query) => query.userId.trim(),
      scopeIdBuilder: (query) => query.buildScopeId(
        schemaVersion: ownerSchemaVersion,
      ),
      fetchRaw: repository._fetchOwnerJobs,
      resolve: (jobs) => jobs,
      isEmpty: (jobs) => jobs.isEmpty,
      schemaVersion: ownerSchemaVersion,
    );
  }
}

extension JobHomeSnapshotRepositoryFieldsPart on JobHomeSnapshotRepository {
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  CacheFirstCoordinator<List<JobModel>> get _coordinator => _state.coordinator;
  EducationTypesenseCacheFirstAdapter<List<JobModel>> get _homeAdapter =>
      _state.homeAdapter;
  EducationTypesenseCacheFirstAdapter<List<JobModel>> get _searchAdapter =>
      _state.searchAdapter;
  CacheFirstQueryPipeline<JobOwnerQuery, List<JobModel>, List<JobModel>>
      get _ownerPipeline => _state.ownerPipeline;
}
