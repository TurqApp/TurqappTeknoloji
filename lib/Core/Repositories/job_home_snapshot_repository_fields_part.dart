part of 'job_home_snapshot_repository.dart';

class _JobHomeSnapshotRepositoryState {
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  late final CacheFirstCoordinator<List<JobModel>> coordinator;
  late final EducationTypesenseCacheFirstAdapter<List<JobModel>> homeAdapter;
  late final EducationTypesenseCacheFirstAdapter<List<JobModel>> searchAdapter;

  void initialize(JobHomeSnapshotRepository repository) {
    coordinator = CacheFirstCoordinator<List<JobModel>>(
      memoryStore: MemoryScopedSnapshotStore<List<JobModel>>(),
      snapshotStore: SharedPrefsScopedSnapshotStore<List<JobModel>>(
        prefsPrefix: 'job_home_snapshot_v1',
        encode: repository._encodeJobs,
        decode: repository._decodeJobs,
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
    homeAdapter = EducationTypesenseCacheFirstAdapter<List<JobModel>>(
      surfaceKey: JobHomeSnapshotRepository._homeSurfaceKey,
      coordinator: coordinator,
      resolve: (raw) => repository._resolveHits(raw.hits),
      loadWarmSnapshot: repository._loadWarmEducationSnapshot,
      isEmpty: (jobs) => jobs.isEmpty,
    );
    searchAdapter = EducationTypesenseCacheFirstAdapter<List<JobModel>>(
      surfaceKey: JobHomeSnapshotRepository._searchSurfaceKey,
      coordinator: coordinator,
      resolve: (raw) => repository._resolveHits(raw.hits),
      loadWarmSnapshot: repository._loadWarmEducationSnapshot,
      isEmpty: (jobs) => jobs.isEmpty,
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
}
