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
part 'short_snapshot_repository_models_part.dart';
part 'short_snapshot_repository_runtime_part.dart';

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
    encode: _performEncodePosts,
    decode: _performDecodePosts,
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
    fetchRaw: (query) => _performFetchEligibleSnapshot(this, query),
    resolve: (items) => items,
    loadWarmSnapshot: (query) => _performLoadWarmSnapshot(this, query),
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
  );
}
