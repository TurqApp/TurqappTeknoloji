part of 'tutoring_snapshot_repository.dart';

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
}
