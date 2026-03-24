import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Models/notification_model.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';

part 'notifications_snapshot_repository_query_part.dart';
part 'notifications_snapshot_repository_action_part.dart';

class NotificationsSnapshotQuery {
  const NotificationsSnapshotQuery({
    required this.userId,
    this.limit = ReadBudgetRegistry.notificationsInboxInitialLimit,
    this.scopeTag = 'inbox',
  });

  final String userId;
  final int limit;
  final String scopeTag;

  String get scopeId => <String>[
        'limit=$limit',
        'scope=${scopeTag.trim()}',
      ].join('|');
}

class NotificationsSnapshotRepository extends GetxService {
  NotificationsSnapshotRepository();

  static const String _surfaceKey = 'notifications_inbox_snapshot';

  static NotificationsSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<NotificationsSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<NotificationsSnapshotRepository>();
  }

  static NotificationsSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(NotificationsSnapshotRepository(), permanent: true);
  }

  final NotificationsRepository _notificationsRepository =
      NotificationsRepository.ensure();
  final RuntimeInvariantGuard _invariantGuard = RuntimeInvariantGuard.ensure();

  late final CacheFirstCoordinator<List<NotificationModel>> _coordinator =
      CacheFirstCoordinator<List<NotificationModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<NotificationModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<NotificationModel>>(
      prefsPrefix: 'notifications_snapshot_v1',
      encode: _encodeItems,
      decode: _decodeItems,
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

  late final CacheFirstQueryPipeline<NotificationsSnapshotQuery,
          List<NotificationModel>, List<NotificationModel>> _pipeline =
      CacheFirstQueryPipeline<NotificationsSnapshotQuery,
          List<NotificationModel>, List<NotificationModel>>(
    surfaceKey: _surfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.scopeId,
    fetchRaw: _fetchServerSnapshot,
    resolve: (items) => items,
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
  );
}
