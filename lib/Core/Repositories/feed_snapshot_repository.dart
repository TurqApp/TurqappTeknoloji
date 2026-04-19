import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/feed_typesense_policy.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/feed_typesense_paging_contract.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/launch_motor_selection_service.dart';
import 'package:turqappv2/Core/Services/launch_motor_surface_contract.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/startup_surface_order_service.dart';
import 'package:turqappv2/Core/Services/typesense_user_card_cache_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

import 'feed_home_contract.dart';

part 'feed_snapshot_repository_fetch_part.dart';
part 'feed_snapshot_repository_codec_part.dart';
part 'feed_snapshot_repository_visibility_part.dart';
part 'feed_snapshot_repository_runtime_part.dart';

abstract class _FeedSnapshotRepositoryBase extends GetxService {
  _FeedSnapshotRepositoryBase() {
    _state = _FeedSnapshotRepositoryState(this as FeedSnapshotRepository);
  }

  late final _FeedSnapshotRepositoryState _state;
}

class FeedSnapshotRepository extends _FeedSnapshotRepositoryBase {
  static const String _homeSurfaceKey = 'feed_home_snapshot';
  static const int _defaultPersistLimit =
      ReadBudgetRegistry.feedHomeInitialLimit;
  static const int startupHomeLimit = _defaultPersistLimit;
  static const int _typesenseStartupAuthorWarmBatchSize = 30;
  static const bool typesensePrimaryEnabled =
      FeedTypesensePolicy.primaryEnabled;
  static const bool typesenseFirestoreFallbackEnabled =
      FeedTypesensePolicy.firestoreFallbackEnabled;
  static FeedPrimarySourceMode resolvePrimarySourceMode({
    required Object? startAfter,
    FeedPrimarySourceMode? override,
    int? typesensePage,
  }) {
    if (override != null) {
      return override;
    }
    if (typesensePage != null && typesensePage > 0) {
      return FeedPrimarySourceMode.typesense;
    }
    if (typesensePrimaryEnabled && startAfter == null) {
      return FeedPrimarySourceMode.typesense;
    }
    return FeedPrimarySourceMode.firestore;
  }

  static int get startupHomeLimitValue =>
      ReadBudgetRegistry.feedHomeInitialLimitValue;
  static const FeedHomeContract _homeContract =
      FeedHomeContract.primaryHybridV1;
}

class _FeedSnapshotRepositoryState {
  _FeedSnapshotRepositoryState(this.repository);

  final FeedSnapshotRepository repository;

  late final PostRepository postRepository = PostRepository.ensure();
  late final RuntimeInvariantGuard invariantGuard =
      ensureRuntimeInvariantGuard();
  late final UserSummaryResolver userSummaryResolver =
      UserSummaryResolver.ensure();
  late final VisibilityPolicyService visibilityPolicy =
      VisibilityPolicyService.ensure();
  late final WarmLaunchPool warmLaunchPool = ensureWarmLaunchPool();
  late final MemoryScopedSnapshotStore<List<PostsModel>> memoryStore =
      MemoryScopedSnapshotStore<List<PostsModel>>();
  late final SharedPrefsScopedSnapshotStore<List<PostsModel>> snapshotStore =
      SharedPrefsScopedSnapshotStore<List<PostsModel>>(
    prefsPrefix: 'feed_snapshot_v2',
    encode: repository._encodePosts,
    decode: repository._decodePosts,
  );
  late final CacheFirstCoordinator<List<PostsModel>> coordinator =
      CacheFirstCoordinator<List<PostsModel>>(
    memoryStore: memoryStore,
    snapshotStore: snapshotStore,
    telemetry: const CacheFirstKpiTelemetry<List<PostsModel>>(),
    policy: CacheFirstPolicyRegistry.policyForSurface(
      FeedSnapshotRepository._homeSurfaceKey,
    ),
  );
  late final CacheFirstQueryPipeline<FeedSnapshotQuery, List<PostsModel>,
          List<PostsModel>> homePipeline =
      CacheFirstQueryPipeline<FeedSnapshotQuery, List<PostsModel>,
          List<PostsModel>>(
    surfaceKey: FeedSnapshotRepository._homeSurfaceKey,
    coordinator: coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.scopeId,
    fetchRaw: repository._fetchHomeSnapshot,
    resolve: (items) => items,
    loadWarmSnapshot: repository._loadWarmHomeSnapshot,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      FeedSnapshotRepository._homeSurfaceKey,
    ),
  );
}

FeedSnapshotRepository? maybeFindFeedSnapshotRepository() {
  final isRegistered = Get.isRegistered<FeedSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<FeedSnapshotRepository>();
}

FeedSnapshotRepository ensureFeedSnapshotRepository() {
  final existing = maybeFindFeedSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(FeedSnapshotRepository(), permanent: true);
}

extension FeedSnapshotRepositoryFieldsPart on FeedSnapshotRepository {
  bool get _shouldLogDiagnostics => kDebugMode && !IntegrationTestMode.enabled;
  PostRepository get _postRepository => _state.postRepository;
  RuntimeInvariantGuard get _invariantGuard => _state.invariantGuard;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  VisibilityPolicyService get _visibilityPolicy => _state.visibilityPolicy;
  WarmLaunchPool get _warmLaunchPool => _state.warmLaunchPool;
  MemoryScopedSnapshotStore<List<PostsModel>> get _memoryStore =>
      _state.memoryStore;
  SharedPrefsScopedSnapshotStore<List<PostsModel>> get _snapshotStore =>
      _state.snapshotStore;
  CacheFirstCoordinator<List<PostsModel>> get _coordinator =>
      _state.coordinator;
  CacheFirstQueryPipeline<FeedSnapshotQuery, List<PostsModel>, List<PostsModel>>
      get _homePipeline => _state.homePipeline;
}

extension FeedSnapshotRepositoryFacadePart on FeedSnapshotRepository {
  Stream<CachedResource<List<PostsModel>>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.feedHomeInitialLimit,
    bool forceSync = false,
  }) {
    final effectiveLimit =
        ReadBudgetRegistry.resolveFeedHomeInitialLimit(limit);
    return _homePipeline.open(
      FeedSnapshotQuery(
        userId: userId,
        limit: effectiveLimit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<PostsModel>>> loadHome({
    required String userId,
    int limit = ReadBudgetRegistry.feedHomeInitialLimit,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Future<void> primeStartupTypesensePage({
    int limit = FeedSnapshotRepository.startupHomeLimit,
    int? nowMs,
  }) async {
    if (!FeedSnapshotRepository.typesensePrimaryEnabled) {
      return;
    }
    final effectiveLimit =
        ReadBudgetRegistry.resolveFeedHomeInitialLimit(limit);
    final anchorMs = startupSurfaceSessionSeed(sessionNamespace: 'feed');
    final ownedMinutes = LaunchMotorSelectionService.resolveOwnedMinutes(
      anchorMs: anchorMs,
      bandMinutes: feedLaunchMotorContract.bandMinutes,
      minuteSets: feedLaunchMotorContract.minuteSets,
    );
    if (ownedMinutes.isEmpty) {
      return;
    }
    final resolvedNowMs = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final candidateLimit = FeedTypesensePolicy.resolveCandidateLimit(
      effectiveLimit,
    );
    try {
      final motorPage = await _postRepository.fetchTypesenseMotorCandidates(
        surface: 'feed',
        ownedMinutes: ownedMinutes,
        limit: candidateLimit,
        page: 1,
        nowMs: resolvedNowMs,
        cutoffMs: _feedHomeCutoffMs(resolvedNowMs),
      );
      final warmAuthorIds = _sortFeedCandidatesForVisibility(
        motorPage.items,
      )
          .take(
            FeedSnapshotRepository._typesenseStartupAuthorWarmBatchSize,
          )
          .where((post) {
            final authorId = post.userID.trim();
            if (authorId.isEmpty) return false;
            if (post.isFloodMember) return false;
            if (post.deletedPost == true) return false;
            if (post.gizlendi) return false;
            if (post.shouldHideWhileUploading) return false;
            if (!_isRenderablePost(post)) return false;
            return _isInAgendaWindow(
              post.timeStamp.toInt(),
              resolvedNowMs,
              _feedHomeCutoffMs(resolvedNowMs),
            );
          })
          .map((post) => post.userID.trim())
          .toSet()
          .toList(growable: false);
      if (warmAuthorIds.isNotEmpty) {
        unawaited(_primeStartupTypesenseAuthorCards(warmAuthorIds));
      }
    } catch (_) {}
  }

  Future<void> _primeStartupTypesenseAuthorCards(List<String> authorIds) async {
    if (authorIds.isEmpty) return;
    try {
      final cards =
          await ensureTypesenseUserCardCacheService().getUserCardsByIds(
        authorIds,
        preferCache: true,
        cacheOnly: false,
      );
      if (cards.isEmpty) return;
      final writes = <Future<void>>[];
      for (final entry in cards.entries) {
        final uid = entry.key.trim();
        final card = entry.value;
        if (uid.isEmpty || card.isEmpty) continue;
        writes.add(_userSummaryResolver.seedRaw(uid, card));
      }
      if (writes.isNotEmpty) {
        await Future.wait(writes);
      }
    } catch (_) {}
  }

  Future<CachedResource<List<PostsModel>>> bootstrapHome({
    required String userId,
    int limit = ReadBudgetRegistry.feedHomeInitialLimit,
  }) =>
      bootstrapFeedHome(
        this,
        userId: userId,
        limit: ReadBudgetRegistry.resolveFeedHomeInitialLimit(limit),
      );

  Future<CachedResource<List<PostsModel>>> inspectWarmHome({
    required String userId,
    int limit = FeedSnapshotRepository.startupHomeLimit,
  }) =>
      inspectWarmFeedHome(
        this,
        userId: userId,
        limit: ReadBudgetRegistry.resolveFeedHomeInitialLimit(limit),
      );

  Future<List<PostsModel>> inspectHomeStartupShard({
    required String userId,
    int limit = FeedSnapshotRepository.startupHomeLimit,
  }) =>
      inspectFeedHomeStartupShard(
        this,
        userId: userId,
        limit: ReadBudgetRegistry.resolveFeedHomeInitialLimit(limit),
      );

  Future<void> persistHomeSnapshot({
    required String userId,
    required List<PostsModel> posts,
    int limit = FeedSnapshotRepository._defaultPersistLimit,
    CachedResourceSource source = CachedResourceSource.server,
    DateTime? snapshotAt,
  }) =>
      persistFeedHomeSnapshot(
        this,
        userId: userId,
        posts: posts,
        limit: ReadBudgetRegistry.resolveFeedHomeInitialLimit(limit),
        source: source,
        snapshotAt: snapshotAt,
      );

  Future<void> clearUserSnapshots({
    String? userId,
  }) =>
      _coordinator.clearSurface(
        FeedSnapshotRepository._homeSurfaceKey,
        userId: userId?.trim().isEmpty ?? true ? null : userId!.trim(),
      );

  Future<void> pruneHomeSnapshots({
    required String userId,
    required Iterable<String> docIds,
    Iterable<int> additionalLimits = const <int>[],
  }) =>
      pruneFeedHomeSnapshots(
        this,
        userId: userId,
        docIds: docIds,
        additionalLimits: additionalLimits,
      );

  Future<void> pruneHomeStartupShard({
    required String userId,
    required Iterable<String> docIds,
  }) =>
      pruneFeedHomeStartupShard(
        this,
        userId: userId,
        docIds: docIds,
      );
}

class FeedSnapshotQuery {
  const FeedSnapshotQuery({
    required this.userId,
    this.limit = ReadBudgetRegistry.feedHomeInitialLimit,
    this.scopeTag = 'home',
  });

  final String userId;
  final int limit;
  final String scopeTag;

  int get effectiveLimit =>
      ReadBudgetRegistry.resolveFeedHomeInitialLimit(limit);

  String get scopeId => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: effectiveLimit,
        scopeTag: scopeTag,
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          FeedSnapshotRepository._homeSurfaceKey,
        ),
      );
}

enum FeedPrimarySourceMode {
  firestore,
  typesense,
}

class FeedSourcePage {
  const FeedSourcePage({
    required this.items,
    required this.lastDoc,
    required this.usesPrimaryFeed,
    required this.itemsPreplanned,
    this.nextTypesensePage,
  });

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool usesPrimaryFeed;
  final bool itemsPreplanned;
  final int? nextTypesensePage;
}
