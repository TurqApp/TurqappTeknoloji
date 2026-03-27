part of 'tutoring_snapshot_repository.dart';

class TutoringSnapshotRepository extends GetxService {
  TutoringSnapshotRepository();

  static const String _homeSurfaceKey = 'tutoring_home_snapshot';
  static const String _searchSurfaceKey = 'tutoring_search_snapshot';

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  late final CacheFirstCoordinator<List<TutoringModel>> _coordinator =
      _buildTutoringSnapshotCoordinator();

  late final EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
      _homeAdapter = _buildTutoringSnapshotAdapter(
    repository: this,
    surfaceKey: TutoringSnapshotRepository._homeSurfaceKey,
  );

  late final EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
      _searchAdapter = _buildTutoringSnapshotAdapter(
    repository: this,
    surfaceKey: TutoringSnapshotRepository._searchSurfaceKey,
  );
}

CacheFirstCoordinator<List<TutoringModel>> _buildTutoringSnapshotCoordinator() {
  return CacheFirstCoordinator<List<TutoringModel>>(
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
}

EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
    _buildTutoringSnapshotAdapter({
  required TutoringSnapshotRepository repository,
  required String surfaceKey,
}) {
  return EducationTypesenseCacheFirstAdapter<List<TutoringModel>>(
    surfaceKey: surfaceKey,
    coordinator: repository._coordinator,
    resolve: (raw) => _resolveTutoringHits(repository, raw.hits),
    loadWarmSnapshot: _loadWarmTutoringSnapshot,
    isEmpty: (items) => items.isEmpty,
  );
}
