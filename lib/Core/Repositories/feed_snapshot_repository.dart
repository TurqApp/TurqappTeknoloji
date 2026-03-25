import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'feed_snapshot_repository_fetch_part.dart';
part 'feed_snapshot_repository_codec_part.dart';
part 'feed_snapshot_repository_visibility_part.dart';

class FeedSnapshotQuery {
  const FeedSnapshotQuery({
    required this.userId,
    this.limit = 30,
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

class FeedSourcePage {
  const FeedSourcePage({
    required this.items,
    required this.lastDoc,
    required this.usesPrimaryFeed,
  });

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool usesPrimaryFeed;
}

class FeedSnapshotRepository extends GetxService {
  FeedSnapshotRepository();

  static const String _homeSurfaceKey = 'feed_home_snapshot';
  static const int _defaultPersistLimit = 40;
  static final Set<String> _hybridBackfillRequested = <String>{};

  bool get _shouldLogDiagnostics => kDebugMode && !IntegrationTestMode.enabled;

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

  final PostRepository _postRepository = PostRepository.ensure();
  final RuntimeInvariantGuard _invariantGuard = RuntimeInvariantGuard.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();
  final WarmLaunchPool _warmLaunchPool = WarmLaunchPool.ensure();

  late final MemoryScopedSnapshotStore<List<PostsModel>> _memoryStore =
      MemoryScopedSnapshotStore<List<PostsModel>>();
  late final SharedPrefsScopedSnapshotStore<List<PostsModel>> _snapshotStore =
      SharedPrefsScopedSnapshotStore<List<PostsModel>>(
    prefsPrefix: 'feed_snapshot_v1',
    encode: _encodePosts,
    decode: _decodePosts,
  );
  late final CacheFirstCoordinator<List<PostsModel>> _coordinator =
      CacheFirstCoordinator<List<PostsModel>>(
    memoryStore: _memoryStore,
    snapshotStore: _snapshotStore,
    telemetry: const CacheFirstKpiTelemetry<List<PostsModel>>(),
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

  late final CacheFirstQueryPipeline<FeedSnapshotQuery, List<PostsModel>,
          List<PostsModel>> _homePipeline =
      CacheFirstQueryPipeline<FeedSnapshotQuery, List<PostsModel>,
          List<PostsModel>>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.scopeId,
    fetchRaw: _fetchHomeSnapshot,
    resolve: (items) => items,
    loadWarmSnapshot: _loadWarmHomeSnapshot,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
  );

  Stream<CachedResource<List<PostsModel>>> openHome({
    required String userId,
    int limit = 30,
    bool forceSync = false,
  }) {
    return _homePipeline.open(
      FeedSnapshotQuery(
        userId: userId,
        limit: limit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<PostsModel>>> loadHome({
    required String userId,
    int limit = 30,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Future<CachedResource<List<PostsModel>>> bootstrapHome({
    required String userId,
    int limit = 30,
  }) {
    final query = FeedSnapshotQuery(
      userId: userId,
      limit: limit,
    );
    return _coordinator.bootstrap(
      _homeKey(query),
      loadWarmSnapshot: () => _loadWarmHomeSnapshot(query),
    );
  }

  Future<void> persistHomeSnapshot({
    required String userId,
    required List<PostsModel> posts,
    int limit = _defaultPersistLimit,
    CachedResourceSource source = CachedResourceSource.server,
  }) async {
    final normalized =
        _normalizePosts(posts).take(limit).toList(growable: false);
    if (normalized.isEmpty) return;
    final key = _homeKey(FeedSnapshotQuery(
      userId: userId,
      limit: limit,
    ));
    final record = ScopedSnapshotRecord<List<PostsModel>>(
      data: normalized,
      snapshotAt: DateTime.now(),
      schemaVersion: 1,
      generationId: 'manual:${DateTime.now().millisecondsSinceEpoch}',
      source: source,
    );
    final userMeta = await _buildUserMeta(normalized);
    await Future.wait(<Future<void>>[
      _memoryStore.write(key, record),
      _snapshotStore.write(key, record),
      _warmLaunchPool.savePosts(
        IndexPoolKind.feed,
        normalized,
        userMeta: userMeta,
      ),
    ]);
  }
}
