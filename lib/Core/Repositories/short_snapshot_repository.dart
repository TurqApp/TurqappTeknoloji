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
    if (!Get.isRegistered<ShortSnapshotRepository>()) return null;
    return Get.find<ShortSnapshotRepository>();
  }

  static ShortSnapshotRepository _ensureService() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ShortSnapshotRepository(), permanent: true);
  }

  static ShortSnapshotRepository ensure() => _ensureService();

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
  }) {
    return _homePipeline.open(
      ShortSnapshotQuery(
        userId: userId,
        limit: limit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<PostsModel>>> bootstrapHome({
    required String userId,
    int limit = _defaultPersistLimit,
  }) {
    final query = ShortSnapshotQuery(
      userId: userId,
      limit: limit,
    );
    return _coordinator.bootstrap(
      ScopedSnapshotKey(
        surfaceKey: _homeSurfaceKey,
        userId: query.userId.trim(),
        scopeId: query.scopeId,
      ),
      loadWarmSnapshot: () => _loadWarmSnapshot(query),
    );
  }

  Future<CachedResource<List<PostsModel>>> loadHome({
    required String userId,
    int limit = _defaultPersistLimit,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
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
    final key = ScopedSnapshotKey(
      surfaceKey: _homeSurfaceKey,
      userId: userId.trim(),
      scopeId: ShortSnapshotQuery(
        userId: userId,
        limit: limit,
      ).scopeId,
    );
    final record = ScopedSnapshotRecord<List<PostsModel>>(
      data: normalized,
      snapshotAt: DateTime.now(),
      schemaVersion: 1,
      generationId: 'manual:${DateTime.now().millisecondsSinceEpoch}',
      source: source,
    );
    await Future.wait(<Future<void>>[
      _memoryStore.write(key, record),
      _snapshotStore.write(key, record),
      _warmLaunchPool.savePosts(IndexPoolKind.shortFullscreen, normalized),
    ]);
  }

  Future<List<PostsModel>> _fetchEligibleSnapshot(
    ShortSnapshotQuery query,
  ) async {
    final followingIds = await _loadFollowingIds(query.userId);
    final me = query.userId.trim();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    final collected = <PostsModel>[];
    final seen = <String>{};

    for (int attempt = 0; attempt < _maxPageSkips; attempt++) {
      final page = await _shortRepository.fetchReadyPage(
        startAfter: cursor,
        pageSize: query.limit,
        nowMs: nowMs,
      );
      if (page.posts.isEmpty) break;

      final eligible = await _filterEligiblePosts(
        page.posts,
        currentUserId: me,
        followingIds: followingIds,
      );
      for (final post in eligible) {
        if (seen.add(post.docID)) {
          collected.add(post);
        }
      }
      if (collected.length >= query.limit) break;
      if (!page.hasMore || page.lastDoc == null) break;
      cursor = page.lastDoc;
    }

    return collected.take(query.limit).toList(growable: false);
  }

  Future<List<PostsModel>?> _loadWarmSnapshot(
    ShortSnapshotQuery query,
  ) async {
    final posts = await _warmLaunchPool.loadPosts(
      IndexPoolKind.shortFullscreen,
      limit: query.limit,
      allowStale: false,
    );
    if (posts.isEmpty) return null;
    final eligible = await _filterEligiblePosts(
      posts,
      currentUserId: query.userId.trim(),
      followingIds: await _loadFollowingIds(query.userId),
    );
    final normalized = eligible.take(query.limit).toList(growable: false);
    if (normalized.length != posts.length) {
      final validIds = normalized.map((post) => post.docID).toSet();
      final invalidIds = posts
          .where((post) => !validIds.contains(post.docID))
          .map((post) => post.docID)
          .toList(growable: false);
      if (invalidIds.isNotEmpty) {
        await _warmLaunchPool.removePosts(
          IndexPoolKind.shortFullscreen,
          invalidIds,
        );
      }
    }
    return normalized.isEmpty ? null : normalized;
  }

  Future<Set<String>> _loadFollowingIds(String userId) async {
    return VisibilityPolicyService.ensure().loadViewerFollowingIds(
      viewerUserId: userId,
      preferCache: true,
    );
  }

  Future<List<PostsModel>> _filterEligiblePosts(
    List<PostsModel> posts, {
    required String currentUserId,
    required Set<String> followingIds,
  }) async {
    if (posts.isEmpty) return const <PostsModel>[];
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final normalized = _normalizePosts(posts)
        .where((post) => post.timeStamp <= nowMs)
        .where((post) => post.deletedPost != true)
        .where((post) => post.arsiv == false)
        .where((post) => post.hasPlayableVideo)
        .toList(growable: false);
    if (normalized.isEmpty) return const <PostsModel>[];

    final authorIds = normalized
        .map((post) => post.userID)
        .where((id) => id.isNotEmpty)
        .toSet();
    final summaries = await _userSummaryResolver.resolveMany(
      authorIds.toList(growable: false),
      preferCache: true,
    );

    final visible = <PostsModel>[];
    for (final post in normalized) {
      final summary = summaries[post.userID];
      if (summary == null) continue;
      final canSeeAuthor = _visibilityPolicy.canViewerSeeAuthorFromSummary(
        authorUserId: post.userID,
        followingIds: followingIds,
        isPrivate: summary.isPrivate,
        isDeleted: summary.isDeleted,
      );
      if (!canSeeAuthor) {
        continue;
      }
      visible.add(
        post.copyWith(
          authorNickname: post.authorNickname.isNotEmpty
              ? post.authorNickname
              : summary.nickname,
          authorDisplayName: post.authorDisplayName.isNotEmpty
              ? post.authorDisplayName
              : summary.displayName,
          authorAvatarUrl: post.authorAvatarUrl.isNotEmpty
              ? post.authorAvatarUrl
              : summary.avatarUrl,
          rozet: post.rozet.isNotEmpty ? post.rozet : summary.rozet,
        ),
      );
    }
    _invariantGuard.assertNotEmptyAfterRefresh(
      surface: 'short',
      invariantKey: 'eligible_visible_after_filter',
      hadSnapshot: normalized.isNotEmpty,
      previousCount: normalized.length,
      nextCount: visible.length,
      payload: <String, dynamic>{
        'currentUserId': currentUserId,
        'followingCount': followingIds.length,
      },
    );
    return visible;
  }

  List<PostsModel> _normalizePosts(List<PostsModel> posts) {
    final seen = <String>{};
    final normalized = <PostsModel>[];
    for (final post in posts) {
      if (post.docID.isEmpty || !seen.add(post.docID)) continue;
      normalized.add(post);
    }
    return normalized;
  }

  Map<String, dynamic> _encodePosts(List<PostsModel> posts) {
    return <String, dynamic>{
      'items': posts
          .map((post) => <String, dynamic>{
                'docID': post.docID,
                ...post.toMap(),
              })
          .toList(growable: false),
    };
  }

  List<PostsModel> _decodePosts(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
          final docId = (item.remove('docID') ?? '').toString();
          return PostsModel.fromMap(item, docId);
        })
        .where((post) => post.docID.isNotEmpty)
        .toList(growable: false);
  }
}
