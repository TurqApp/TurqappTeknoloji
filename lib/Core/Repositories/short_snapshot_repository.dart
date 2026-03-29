import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/short_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'short_snapshot_repository_query_part.dart';
part 'short_snapshot_repository_visibility_part.dart';
part 'short_snapshot_repository_runtime_part.dart';

class ShortSnapshotRepository extends GetxService {
  late final _ShortSnapshotRepositoryShellState _shellState;
  ShortSnapshotRepository() {
    _shellState = _ShortSnapshotRepositoryShellState(this);
  }

  static const String _homeSurfaceKey = 'short_home_snapshot';
  static const int _defaultPersistLimit =
      ReadBudgetRegistry.shortHomeInitialLimit;
  static const int _maxPageSkips = 4;
}

class ShortSnapshotQuery {
  const ShortSnapshotQuery({
    required this.userId,
    this.limit = ReadBudgetRegistry.shortHomeInitialLimit,
    this.scopeTag = 'home',
  });

  final String userId;
  final int limit;
  final String scopeTag;

  String get scopeId => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: limit,
        scopeTag: scopeTag,
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          ShortSnapshotRepository._homeSurfaceKey,
        ),
      );
}

class _ShortSnapshotRepositoryShellState {
  _ShortSnapshotRepositoryShellState(this.repository)
      : shortRepository = ensureShortRepository(),
        invariantGuard = ensureRuntimeInvariantGuard(),
        userSummaryResolver = UserSummaryResolver.ensure(),
        visibilityPolicy = VisibilityPolicyService.ensure(),
        warmLaunchPool = ensureWarmLaunchPool(),
        memoryStore = MemoryScopedSnapshotStore<List<PostsModel>>(),
        snapshotStore = SharedPrefsScopedSnapshotStore<List<PostsModel>>(
          prefsPrefix: 'short_snapshot_v1',
          encode: _performEncodePosts,
          decode: _performDecodePosts,
        ) {
    coordinator = CacheFirstCoordinator<List<PostsModel>>(
      memoryStore: memoryStore,
      snapshotStore: snapshotStore,
      telemetry: const CacheFirstKpiTelemetry<List<PostsModel>>(),
      policy: CacheFirstPolicyRegistry.policyForSurface(
        ShortSnapshotRepository._homeSurfaceKey,
      ),
    );
    homePipeline = CacheFirstQueryPipeline<ShortSnapshotQuery, List<PostsModel>,
        List<PostsModel>>(
      surfaceKey: ShortSnapshotRepository._homeSurfaceKey,
      coordinator: coordinator,
      userIdResolver: (query) => query.userId.trim(),
      scopeIdBuilder: (query) => query.scopeId,
      fetchRaw: (query) => _performFetchEligibleSnapshot(repository, query),
      resolve: (items) => items,
      loadWarmSnapshot: (query) => _performLoadWarmSnapshot(repository, query),
      isEmpty: (items) => items.isEmpty,
      liveSource: CachedResourceSource.server,
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        ShortSnapshotRepository._homeSurfaceKey,
      ),
    );
  }

  final ShortSnapshotRepository repository;
  final ShortRepository shortRepository;
  final RuntimeInvariantGuard invariantGuard;
  final UserSummaryResolver userSummaryResolver;
  final VisibilityPolicyService visibilityPolicy;
  final WarmLaunchPool warmLaunchPool;
  final MemoryScopedSnapshotStore<List<PostsModel>> memoryStore;
  final SharedPrefsScopedSnapshotStore<List<PostsModel>> snapshotStore;
  late CacheFirstCoordinator<List<PostsModel>> coordinator;
  late CacheFirstQueryPipeline<ShortSnapshotQuery, List<PostsModel>,
      List<PostsModel>> homePipeline;
}

ShortSnapshotRepository? maybeFindShortSnapshotRepository() =>
    Get.isRegistered<ShortSnapshotRepository>()
        ? Get.find<ShortSnapshotRepository>()
        : null;

ShortSnapshotRepository ensureShortSnapshotRepository() =>
    maybeFindShortSnapshotRepository() ??
    Get.put(ShortSnapshotRepository(), permanent: true);

extension ShortSnapshotRepositoryFieldsPart on ShortSnapshotRepository {
  ShortRepository get _shortRepository => _shellState.shortRepository;
  RuntimeInvariantGuard get _invariantGuard => _shellState.invariantGuard;
  UserSummaryResolver get _userSummaryResolver =>
      _shellState.userSummaryResolver;
  VisibilityPolicyService get _visibilityPolicy => _shellState.visibilityPolicy;
  WarmLaunchPool get _warmLaunchPool => _shellState.warmLaunchPool;
  MemoryScopedSnapshotStore<List<PostsModel>> get _memoryStore =>
      _shellState.memoryStore;
  SharedPrefsScopedSnapshotStore<List<PostsModel>> get _snapshotStore =>
      _shellState.snapshotStore;
  CacheFirstCoordinator<List<PostsModel>> get _coordinator =>
      _shellState.coordinator;
  CacheFirstQueryPipeline<ShortSnapshotQuery, List<PostsModel>,
      List<PostsModel>> get _homePipeline => _shellState.homePipeline;
}

extension ShortSnapshotRepositoryFacadePart on ShortSnapshotRepository {
  Future<void> clearUserSnapshots({
    String? userId,
  }) =>
      _coordinator.clearSurface(
        ShortSnapshotRepository._homeSurfaceKey,
        userId: userId?.trim().isEmpty ?? true ? null : userId!.trim(),
      );
}
