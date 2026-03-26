part of 'notifications_snapshot_repository.dart';

class NotificationsSnapshotRepository
    extends _NotificationsSnapshotRepositoryBase {
  NotificationsSnapshotRepository();

  static const String _surfaceKey = _notificationsInboxSnapshotSurfaceKey;

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
}
