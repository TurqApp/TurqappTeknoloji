part of 'notifications_snapshot_repository.dart';

NotificationsSnapshotRepository? maybeFindNotificationsSnapshotRepository() {
  final isRegistered = Get.isRegistered<NotificationsSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<NotificationsSnapshotRepository>();
}

NotificationsSnapshotRepository ensureNotificationsSnapshotRepository() {
  final existing = maybeFindNotificationsSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(NotificationsSnapshotRepository(), permanent: true);
}
