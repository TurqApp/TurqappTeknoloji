part of 'notifications_snapshot_repository.dart';

abstract class _NotificationsSnapshotRepositoryBase extends GetxService {
  late final _NotificationsSnapshotRepositoryState _state =
      _NotificationsSnapshotRepositoryState(
    this as NotificationsSnapshotRepository,
  );
}
