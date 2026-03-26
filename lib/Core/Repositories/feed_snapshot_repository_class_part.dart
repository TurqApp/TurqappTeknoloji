part of 'feed_snapshot_repository.dart';

class FeedSnapshotRepository extends _FeedSnapshotRepositoryBase {
  static const String _homeSurfaceKey = 'feed_home_snapshot';
  static const int _defaultPersistLimit = 40;
  static final Set<String> _hybridBackfillRequested = <String>{};
}
