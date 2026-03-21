import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Models/posts_model.dart';

class ProfilePostsSnapshotQuery {
  const ProfilePostsSnapshotQuery({
    required this.userId,
    this.limit = 24,
    this.scopeTag = 'my_profile',
  });

  final String userId;
  final int limit;
  final String scopeTag;

  String get scopeId => <String>[
        'limit=$limit',
        'scope=${scopeTag.trim()}',
      ].join('|');
}

class ProfilePostsSnapshotRepository extends GetxService {
  ProfilePostsSnapshotRepository();

  static const String _surfaceKey = 'profile_posts_snapshot';

  static ProfilePostsSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ProfilePostsSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<ProfilePostsSnapshotRepository>();
  }

  static ProfilePostsSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfilePostsSnapshotRepository(), permanent: true);
  }

  final ProfileRepository _profileRepository = ProfileRepository.ensure();

  late final MemoryScopedSnapshotStore<ProfileBuckets> _memoryStore =
      MemoryScopedSnapshotStore<ProfileBuckets>();
  late final SharedPrefsScopedSnapshotStore<ProfileBuckets> _snapshotStore =
      SharedPrefsScopedSnapshotStore<ProfileBuckets>(
    prefsPrefix: 'profile_posts_snapshot_v1',
    encode: _encodeBuckets,
    decode: _decodeBuckets,
  );

  late final CacheFirstCoordinator<ProfileBuckets> _coordinator =
      CacheFirstCoordinator<ProfileBuckets>(
    memoryStore: _memoryStore,
    snapshotStore: _snapshotStore,
    telemetry: const CacheFirstKpiTelemetry<ProfileBuckets>(),
    policy: const CacheFirstPolicy(
      snapshotTtl: Duration(minutes: 10),
      minLiveSyncInterval: Duration(seconds: 20),
      syncOnOpen: true,
      allowWarmLaunchFallback: true,
      persistWarmLaunchSnapshot: true,
      treatWarmLaunchAsStale: true,
      preservePreviousOnEmptyLive: true,
    ),
  );

  late final CacheFirstQueryPipeline<ProfilePostsSnapshotQuery, ProfileBuckets,
          ProfileBuckets> _pipeline =
      CacheFirstQueryPipeline<ProfilePostsSnapshotQuery, ProfileBuckets,
          ProfileBuckets>(
    surfaceKey: _surfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.scopeId,
    fetchRaw: _fetchBuckets,
    resolve: (buckets) => buckets,
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (buckets) =>
        buckets.all.isEmpty &&
        buckets.photos.isEmpty &&
        buckets.videos.isEmpty &&
        buckets.scheduled.isEmpty,
    liveSource: CachedResourceSource.server,
  );

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
        surfaceKey: _surfaceKey,
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
      surfaceKey: _surfaceKey,
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

  Future<ProfileBuckets> _fetchBuckets(ProfilePostsSnapshotQuery query) async {
    final page = await _profileRepository.fetchPrimaryPage(
      uid: query.userId,
      limit: query.limit,
    );
    return ProfileBuckets(
      all: page.all,
      photos: page.photos,
      videos: page.videos,
      scheduled: page.scheduled,
    );
  }

  Future<ProfileBuckets?> _loadWarmSnapshot(
    ProfilePostsSnapshotQuery query,
  ) {
    return _profileRepository.readCachedBuckets(query.userId);
  }

  Map<String, dynamic> _encodeBuckets(ProfileBuckets buckets) {
    Map<String, dynamic> encodePosts(List<PostsModel> posts) {
      return <String, dynamic>{
        'items': posts
            .map((post) => <String, dynamic>{
                  'docID': post.docID,
                  'data': post.toMap(),
                })
            .toList(growable: false),
      };
    }

    return <String, dynamic>{
      'all': encodePosts(buckets.all),
      'photos': encodePosts(buckets.photos),
      'videos': encodePosts(buckets.videos),
      'scheduled': encodePosts(buckets.scheduled),
    };
  }

  ProfileBuckets _decodeBuckets(Map<String, dynamic> json) {
    List<PostsModel> decodePosts(dynamic rawBucket) {
      if (rawBucket is! Map) return const <PostsModel>[];
      final items = rawBucket['items'];
      if (items is! List) return const <PostsModel>[];
      return items
          .whereType<Map>()
          .map((raw) {
            final docId = (raw['docID'] ?? '').toString().trim();
            final data = raw['data'];
            if (docId.isEmpty || data is! Map) return null;
            try {
              return PostsModel.fromMap(
                Map<String, dynamic>.from(data.cast<dynamic, dynamic>()),
                docId,
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<PostsModel>()
          .toList(growable: false);
    }

    return ProfileBuckets(
      all: decodePosts(json['all']),
      photos: decodePosts(json['photos']),
      videos: decodePosts(json['videos']),
      scheduled: decodePosts(json['scheduled']),
    );
  }
}
