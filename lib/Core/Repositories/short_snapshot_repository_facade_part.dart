part of 'short_snapshot_repository.dart';

ShortSnapshotRepository? maybeFindShortSnapshotRepository() {
  final isRegistered = Get.isRegistered<ShortSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<ShortSnapshotRepository>();
}

ShortSnapshotRepository ensureShortSnapshotRepository() {
  final existing = maybeFindShortSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(ShortSnapshotRepository(), permanent: true);
}
