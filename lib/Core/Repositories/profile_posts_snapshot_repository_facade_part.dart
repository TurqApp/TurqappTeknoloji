part of 'profile_posts_snapshot_repository.dart';

extension ProfilePostsSnapshotRepositoryFacadePart
    on ProfilePostsSnapshotRepository {
  Stream<CachedResource<ProfileBuckets>> openProfile({
    required String userId,
    int limit = 24,
    bool forceSync = false,
  }) {
    return _pipeline.open(
      ProfilePostsSnapshotQuery(
        userId: userId,
        limit: limit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<ProfileBuckets>> loadProfile({
    required String userId,
    int limit = 24,
    bool forceSync = false,
  }) {
    return openProfile(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Future<CachedResource<ProfileBuckets>> bootstrapProfile({
    required String userId,
    int limit = 24,
  }) {
    final query = ProfilePostsSnapshotQuery(
      userId: userId,
      limit: limit,
    );
    return _coordinator.bootstrap(
      ScopedSnapshotKey(
        surfaceKey: ProfilePostsSnapshotRepository._surfaceKey,
        userId: query.userId.trim(),
        scopeId: query.scopeId,
      ),
      loadWarmSnapshot: () => _loadWarmSnapshot(query),
    );
  }

  Future<void> persistBuckets({
    required String userId,
    required ProfileBuckets buckets,
    int limit = 24,
    CachedResourceSource source = CachedResourceSource.server,
  }) async {
    if (userId.trim().isEmpty) return;
    final normalized = ProfileBuckets(
      all: buckets.all.take(limit).toList(growable: false),
      photos: buckets.photos.take(limit).toList(growable: false),
      videos: buckets.videos.take(limit).toList(growable: false),
      scheduled: buckets.scheduled.take(limit).toList(growable: false),
    );
    final query = ProfilePostsSnapshotQuery(
      userId: userId,
      limit: limit,
    );
    final key = ScopedSnapshotKey(
      surfaceKey: ProfilePostsSnapshotRepository._surfaceKey,
      userId: query.userId.trim(),
      scopeId: query.scopeId,
    );
    final record = ScopedSnapshotRecord<ProfileBuckets>(
      data: normalized,
      snapshotAt: DateTime.now(),
      schemaVersion: 1,
      generationId: 'manual:${DateTime.now().millisecondsSinceEpoch}',
      source: source,
    );
    await Future.wait(<Future<void>>[
      _memoryStore.write(key, record),
      _snapshotStore.write(key, record),
      _profileRepository.writeBuckets(userId, normalized),
    ]);
  }
}
