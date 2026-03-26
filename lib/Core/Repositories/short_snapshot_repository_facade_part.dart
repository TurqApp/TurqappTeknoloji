part of 'short_snapshot_repository.dart';

ShortSnapshotRepository? maybeFindShortSnapshotRepository() =>
    Get.isRegistered<ShortSnapshotRepository>()
        ? Get.find<ShortSnapshotRepository>()
        : null;

ShortSnapshotRepository ensureShortSnapshotRepository() =>
    maybeFindShortSnapshotRepository() ??
    Get.put(ShortSnapshotRepository(), permanent: true);
