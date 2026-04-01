part of 'notifications_snapshot_repository.dart';

const String _notificationsInboxSnapshotSurfaceKey =
    'notifications_inbox_snapshot';

class _NotificationsSnapshotRepositoryState {
  _NotificationsSnapshotRepositoryState(NotificationsSnapshotRepository owner)
      : notificationsRepository = NotificationsRepository.ensure(),
        invariantGuard = ensureRuntimeInvariantGuard() {
    final schemaVersion = CacheFirstPolicyRegistry.schemaVersionForSurface(
      _notificationsInboxSnapshotSurfaceKey,
    );
    coordinator = CacheFirstCoordinator<List<NotificationModel>>(
      memoryStore: MemoryScopedSnapshotStore<List<NotificationModel>>(),
      snapshotStore: SharedPrefsScopedSnapshotStore<List<NotificationModel>>(
        prefsPrefix: 'notifications_snapshot_v1',
        encode: owner._encodeItems,
        decode: owner._decodeItems,
      ),
      telemetry: const CacheFirstKpiTelemetry<List<NotificationModel>>(),
      policy: CacheFirstPolicyRegistry.policyForSurface(
        _notificationsInboxSnapshotSurfaceKey,
      ),
    );

    pipeline = CacheFirstQueryPipeline<NotificationsSnapshotQuery,
        List<NotificationModel>, List<NotificationModel>>(
      surfaceKey: _notificationsInboxSnapshotSurfaceKey,
      coordinator: coordinator,
      userIdResolver: (query) => query.userId.trim(),
      scopeIdBuilder: (query) => query.scopeId,
      fetchRaw: owner._fetchServerSnapshot,
      resolve: (items) => items,
      loadWarmSnapshot: owner._loadWarmSnapshot,
      isEmpty: (items) => items.isEmpty,
      liveSource: CachedResourceSource.server,
      schemaVersion: schemaVersion,
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
