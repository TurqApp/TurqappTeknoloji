part of 'tutoring_snapshot_repository.dart';

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
