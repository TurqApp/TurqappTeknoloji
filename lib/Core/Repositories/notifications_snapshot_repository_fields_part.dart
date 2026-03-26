part of 'notifications_snapshot_repository.dart';

class _NotificationsSnapshotRepositoryState {
  _NotificationsSnapshotRepositoryState(NotificationsSnapshotRepository owner)
      : notificationsRepository = NotificationsRepository.ensure(),
        invariantGuard = ensureRuntimeInvariantGuard() {
    coordinator = CacheFirstCoordinator<List<NotificationModel>>(
      memoryStore: MemoryScopedSnapshotStore<List<NotificationModel>>(),
      snapshotStore: SharedPrefsScopedSnapshotStore<List<NotificationModel>>(
        prefsPrefix: 'notifications_snapshot_v1',
        encode: owner._encodeItems,
        decode: owner._decodeItems,
      ),
      telemetry: const CacheFirstKpiTelemetry<List<NotificationModel>>(),
      policy: const CacheFirstPolicy(
        snapshotTtl: Duration(minutes: 10),
        minLiveSyncInterval: Duration(seconds: 20),
        syncOnOpen: true,
        allowWarmLaunchFallback: true,
        persistWarmLaunchSnapshot: true,
        treatWarmLaunchAsStale: true,
        preservePreviousOnEmptyLive: true,
      ),
    );

    pipeline = CacheFirstQueryPipeline<NotificationsSnapshotQuery,
        List<NotificationModel>, List<NotificationModel>>(
      surfaceKey: NotificationsSnapshotRepository._surfaceKey,
      coordinator: coordinator,
      userIdResolver: (query) => query.userId.trim(),
      scopeIdBuilder: (query) => query.scopeId,
      fetchRaw: owner._fetchServerSnapshot,
      resolve: (items) => items,
      loadWarmSnapshot: owner._loadWarmSnapshot,
      isEmpty: (items) => items.isEmpty,
      liveSource: CachedResourceSource.server,
    );
  }

  final NotificationsRepository notificationsRepository;
  final RuntimeInvariantGuard invariantGuard;
  late final CacheFirstCoordinator<List<NotificationModel>> coordinator;
  late final CacheFirstQueryPipeline<NotificationsSnapshotQuery,
      List<NotificationModel>, List<NotificationModel>> pipeline;
}

extension _NotificationsSnapshotRepositoryFieldsPart
    on NotificationsSnapshotRepository {
  NotificationsRepository get _notificationsRepository =>
      _state.notificationsRepository;
  RuntimeInvariantGuard get _invariantGuard => _state.invariantGuard;
  CacheFirstCoordinator<List<NotificationModel>> get _coordinator =>
      _state.coordinator;
  CacheFirstQueryPipeline<NotificationsSnapshotQuery, List<NotificationModel>,
      List<NotificationModel>> get _pipeline => _state.pipeline;
}
