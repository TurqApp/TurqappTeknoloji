part of 'feed_snapshot_repository.dart';

class FeedSnapshotRepository extends GetxService {
  FeedSnapshotRepository() {
    _state = _FeedSnapshotRepositoryState(this);
  }

  static const String _homeSurfaceKey = 'feed_home_snapshot';
  static const int _defaultPersistLimit = 40;
  static final Set<String> _hybridBackfillRequested = <String>{};
  late final _FeedSnapshotRepositoryState _state;

  static FeedSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<FeedSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<FeedSnapshotRepository>();
  }

  static FeedSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(FeedSnapshotRepository(), permanent: true);
  }
}
