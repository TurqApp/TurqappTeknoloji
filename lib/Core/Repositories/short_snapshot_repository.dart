import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/short_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'short_snapshot_repository_query_part.dart';
part 'short_snapshot_repository_visibility_part.dart';

class ShortSnapshotQuery {
  const ShortSnapshotQuery({
    required this.userId,
    this.limit = 20,
    this.scopeTag = 'home',
  });

  final String userId;
  final int limit;
  final String scopeTag;

  String get scopeId => <String>[
        'limit=$limit',
        'scope=${scopeTag.trim()}',
      ].join('|');
}

class ShortSnapshotRepository extends GetxService {
  ShortSnapshotRepository();

  static const String _homeSurfaceKey = 'short_home_snapshot';
  static const int _defaultPersistLimit = 20;
  static const int _maxPageSkips = 4;

  static ShortSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ShortSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<ShortSnapshotRepository>();
  }

  static ShortSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ShortSnapshotRepository(), permanent: true);
  }

  final ShortRepository _shortRepository = ShortRepository.ensure();
  final RuntimeInvariantGuard _invariantGuard = RuntimeInvariantGuard.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();
  final WarmLaunchPool _warmLaunchPool = WarmLaunchPool.ensure();

  late final MemoryScopedSnapshotStore<List<PostsModel>> _memoryStore =
      MemoryScopedSnapshotStore<List<PostsModel>>();
  late final SharedPrefsScopedSnapshotStore<List<PostsModel>> _snapshotStore =
      SharedPrefsScopedSnapshotStore<List<PostsModel>>(
    prefsPrefix: 'short_snapshot_v1',
    encode: _encodePosts,
    decode: _decodePosts,
  );

  late final CacheFirstCoordinator<List<PostsModel>> _coordinator =
      CacheFirstCoordinator<List<PostsModel>>(
    memoryStore: _memoryStore,
    snapshotStore: _snapshotStore,
    telemetry: const CacheFirstKpiTelemetry<List<PostsModel>>(),
    policy: const CacheFirstPolicy(
      snapshotTtl: Duration(minutes: 12),
      minLiveSyncInterval: Duration(seconds: 20),
      syncOnOpen: true,
      allowWarmLaunchFallback: true,
      persistWarmLaunchSnapshot: true,
      treatWarmLaunchAsStale: true,
      preservePreviousOnEmptyLive: true,
    ),
  );

  late final CacheFirstQueryPipeline<ShortSnapshotQuery, List<PostsModel>,
          List<PostsModel>> _homePipeline =
      CacheFirstQueryPipeline<ShortSnapshotQuery, List<PostsModel>,
          List<PostsModel>>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.scopeId,
    fetchRaw: _fetchEligibleSnapshot,
    resolve: (items) => items,
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
  );

  Stream<CachedResource<List<PostsModel>>> openHome({
    required String userId,
    int limit = _defaultPersistLimit,
    bool forceSync = false,
  }) =>
      _openHome(
        this,
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Future<CachedResource<List<PostsModel>>> bootstrapHome({
    required String userId,
    int limit = _defaultPersistLimit,
  }) =>
      _bootstrapHome(
        this,
        userId: userId,
        limit: limit,
      );

  Future<CachedResource<List<PostsModel>>> loadHome({
    required String userId,
    int limit = _defaultPersistLimit,
    bool forceSync = false,
  }) =>
      _loadHome(
        this,
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Future<void> persistHomeSnapshot({
    required String userId,
    required List<PostsModel> posts,
    int limit = _defaultPersistLimit,
    CachedResourceSource source = CachedResourceSource.server,
  }) =>
      _persistHomeSnapshot(
        this,
        userId: userId,
        posts: posts,
        limit: limit,
        source: source,
      );

  Future<List<PostsModel>> _fetchEligibleSnapshot(
    ShortSnapshotQuery query,
  ) =>
      _performFetchEligibleSnapshot(
        this,
        query,
      );

  Future<List<PostsModel>?> _loadWarmSnapshot(
    ShortSnapshotQuery query,
  ) =>
      _performLoadWarmSnapshot(
        this,
        query,
      );

  Future<Set<String>> _loadFollowingIds(String userId) =>
      _performLoadFollowingIds(
        this,
        userId,
      );

  Future<List<PostsModel>> _filterEligiblePosts(
    List<PostsModel> posts, {
    required String currentUserId,
    required Set<String> followingIds,
  }) =>
      _performFilterEligiblePosts(
        this,
        posts,
        currentUserId: currentUserId,
        followingIds: followingIds,
      );

  List<PostsModel> _normalizePosts(List<PostsModel> posts) =>
      _performNormalizePosts(posts);

  Map<String, dynamic> _encodePosts(List<PostsModel> posts) =>
      _performEncodePosts(posts);

  List<PostsModel> _decodePosts(Map<String, dynamic> json) =>
      _performDecodePosts(json);
}
