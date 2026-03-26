part of 'notifications_snapshot_repository.dart';

NotificationsSnapshotRepository? maybeFindNotificationsSnapshotRepository() =>
    Get.isRegistered<NotificationsSnapshotRepository>()
        ? Get.find<NotificationsSnapshotRepository>()
        : null;

NotificationsSnapshotRepository ensureNotificationsSnapshotRepository() =>
    maybeFindNotificationsSnapshotRepository() ??
    Get.put(NotificationsSnapshotRepository(), permanent: true);
