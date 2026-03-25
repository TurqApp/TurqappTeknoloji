import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'profile_posts_snapshot_repository_models_part.dart';
part 'profile_posts_snapshot_repository_codec_part.dart';
part 'profile_posts_snapshot_repository_facade_part.dart';

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
}
