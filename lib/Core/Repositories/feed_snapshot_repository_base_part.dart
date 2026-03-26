part of 'feed_snapshot_repository.dart';

abstract class _FeedSnapshotRepositoryBase extends GetxService {
  _FeedSnapshotRepositoryBase() {
    _state = _FeedSnapshotRepositoryState(this as FeedSnapshotRepository);
  }

  late final _FeedSnapshotRepositoryState _state;
}
