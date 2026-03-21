import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

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

  static FeedSnapshotRepository ensure() {
    if (Get.isRegistered<FeedSnapshotRepository>()) {
      return Get.find<FeedSnapshotRepository>();
    }
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

  Future<FeedSourcePage> fetchHomePage({
    required String userId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    bool preferCache = true,
    bool cacheOnly = false,
    bool usePrimaryFeedPaging = true,
  }) async {
    final normalizedUserId = userId.trim();
    if (!usePrimaryFeedPaging || normalizedUserId.isEmpty) {
      return _loadLegacyPage(
        currentUserId: normalizedUserId,
        followingIds: followingIds,
        hiddenPostIds: hiddenPostIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        startAfter: startAfter,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
    }

    var refsPage = await _postRepository.fetchUserFeedReferences(
      uid: normalizedUserId,
      limit: limit,
      startAfter: startAfter,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );

    var refs = refsPage.items
        .where((item) => _isEligibleFeedReference(item, nowMs, cutoffMs))
        .toList(growable: false);

    if (kDebugMode) {
      debugPrint(
        '[FeedSnapshot] uid=$normalizedUserId startAfter=${startAfter?.id ?? ''} '
        'refs=${refsPage.items.length} eligible=${refs.length} limit=$limit',
      );
    }

    if (refs.isEmpty && startAfter == null) {
      final repaired = await _tryRepairHybridFeed(
        userId: normalizedUserId,
        limit: limit,
      );
      if (repaired) {
        refsPage = await _postRepository.fetchUserFeedReferences(
          uid: normalizedUserId,
          limit: limit,
          startAfter: null,
          preferCache: false,
          cacheOnly: false,
        );
        refs = refsPage.items
            .where((item) => _isEligibleFeedReference(item, nowMs, cutoffMs))
            .toList(growable: false);
        if (kDebugMode) {
          debugPrint(
            '[FeedSnapshot] uid=$normalizedUserId repairRefetch refs=${refsPage.items.length} '
            'eligible=${refs.length}',
          );
        }
      }
    }

    final postIds = refs.map((item) => item.postId).toList(growable: false);
    final postsById = postIds.isEmpty
        ? const <String, PostsModel>{}
        : await _postRepository.fetchPostCardsByIds(
            postIds,
            preferCache: preferCache,
            cacheOnly: cacheOnly,
          );

    final merged = <String, PostsModel>{};
    for (final ref in refs) {
      final post = postsById[ref.postId];
      if (post == null) continue;
      merged[post.docID] = post;
    }

    final celebIds = await _postRepository.fetchCelebrityAuthorIds(
      <String>{normalizedUserId, ...followingIds}.toList(growable: false),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    if (celebIds.isNotEmpty) {
      final celebPosts = await _postRepository.fetchRecentPostsForAuthors(
        celebIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        perAuthorLimit:
            max(2, (limit / celebIds.length.clamp(1, limit)).ceil()),
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      for (final post in celebPosts) {
        merged.putIfAbsent(post.docID, () => post);
      }
    }

    final publicScheduled = await _fetchVisiblePublicIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit < 20 ? 20 : limit,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    for (final post in publicScheduled) {
      merged.putIfAbsent(post.docID, () => post);
    }

    if (kDebugMode) {
      debugPrint(
        '[FeedSnapshot] uid=$normalizedUserId merged=${merged.length} '
        'celebAuthors=${celebIds.length} publicScheduled=${publicScheduled.length}',
      );
    }

    if (merged.isEmpty && refsPage.lastDoc == null && startAfter == null) {
      if (kDebugMode) {
        debugPrint(
          '[FeedSnapshot] uid=$normalizedUserId fallback=personal reason=primary_empty',
        );
      }
      final personalFallback = await _loadPersonalFallbackPage(
        currentUserId: normalizedUserId,
        followingIds: followingIds,
        hiddenPostIds: hiddenPostIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      if (personalFallback.items.isNotEmpty) {
        return personalFallback;
      }
      if (kDebugMode) {
        debugPrint(
          '[FeedSnapshot] uid=$normalizedUserId fallback=legacy reason=personal_empty',
        );
      }
      return _loadLegacyPage(
        currentUserId: normalizedUserId,
        followingIds: followingIds,
        hiddenPostIds: hiddenPostIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        startAfter: null,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
    }

    final visible = await filterVisiblePosts(
      merged.values.toList(growable: false),
      currentUserId: normalizedUserId,
      followingIds: followingIds,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
    );

    if (kDebugMode) {
      debugPrint(
        '[FeedSnapshot] uid=$normalizedUserId visible=${visible.length} '
        'sample=${visible.take(5).map((post) => post.docID).join(',')}',
      );
    }
    _invariantGuard.assertNotEmptyAfterRefresh(
      surface: 'feed',
      invariantKey: 'snapshot_visible_after_filter',
      hadSnapshot: merged.isNotEmpty,
      previousCount: merged.length,
      nextCount: visible.length,
      payload: <String, dynamic>{
        'uid': normalizedUserId,
        'refsCount': refs.length,
        'usesPrimaryFeed': true,
      },
    );

    return FeedSourcePage(
      items: visible,
      lastDoc: refsPage.lastDoc,
      usesPrimaryFeed: true,
    );
  }

  Future<FeedSourcePage> _loadPersonalFallbackPage({
    required String currentUserId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    if (currentUserId.isEmpty) {
      return const FeedSourcePage(
        items: <PostsModel>[],
        lastDoc: null,
        usesPrimaryFeed: false,
      );
    }

    final merged = <String, PostsModel>{};

    final ownPosts = await _postRepository.fetchRecentPostsForAuthors(
      <String>[currentUserId],
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      perAuthorLimit: limit,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    for (final post in ownPosts) {
      merged[post.docID] = post;
    }

    if (followingIds.isNotEmpty) {
      final followingSeed = followingIds.toList(growable: false);
      final perAuthorLimit = followingSeed.length > 150
          ? 1
          : followingSeed.length > 50
              ? 2
              : 3;
      final followingPosts = await _postRepository.fetchRecentPostsForAuthors(
        followingSeed,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        perAuthorLimit: perAuthorLimit,
        maxConcurrent: 10,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      for (final post in followingPosts) {
        merged.putIfAbsent(post.docID, () => post);
      }
    }

    final publicScheduled = await _fetchVisiblePublicIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit < 20 ? 20 : limit,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    for (final post in publicScheduled) {
      merged.putIfAbsent(post.docID, () => post);
    }

    final visible = await filterVisiblePosts(
      merged.values.toList(growable: false),
      currentUserId: currentUserId,
      followingIds: followingIds,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
    );

    if (kDebugMode) {
      debugPrint(
        '[FeedSnapshot] uid=$currentUserId personalFallback own=${ownPosts.length} '
        'followingSeed=${followingIds.length} '
        'merged=${merged.length} visible=${visible.length}',
      );
    }

    return FeedSourcePage(
      items: visible,
      lastDoc: null,
      usesPrimaryFeed: false,
    );
  }

  Future<bool> _tryRepairHybridFeed({
    required String userId,
    required int limit,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return false;
    if (_hybridBackfillRequested.contains(normalizedUserId)) return false;
    _hybridBackfillRequested.add(normalizedUserId);
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('backfillHybridFeedForUser');
      final response = await callable.call(<String, dynamic>{
        'uid': normalizedUserId,
        'perAuthorLimit': limit < 20 ? 3 : 4,
      });
      if (kDebugMode) {
        debugPrint(
          '[FeedSnapshot] uid=$normalizedUserId repairTriggered result=${response.data}',
        );
      }
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[FeedSnapshot] uid=$normalizedUserId repairFailed error=$error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      return false;
    }
  }

  Future<List<PostsModel>> _fetchHomeSnapshot(
    FeedSnapshotQuery query,
  ) async {
    final userId = query.userId.trim();
    if (userId.isEmpty) return const <PostsModel>[];
    final followingIds = await _loadFollowingIds(userId);
    final page = await fetchHomePage(
      userId: userId,
      followingIds: followingIds,
      hiddenPostIds: const <String>{},
      nowMs: DateTime.now().millisecondsSinceEpoch,
      cutoffMs: 0,
      limit: query.limit,
      preferCache: true,
      cacheOnly: false,
      usePrimaryFeedPaging: true,
    );
    return page.items;
  }

  Future<List<PostsModel>?> _loadWarmHomeSnapshot(
    FeedSnapshotQuery query,
  ) async {
    final posts = await _warmLaunchPool.loadPosts(
      IndexPoolKind.feed,
      limit: query.limit,
      allowStale: true,
    );
    if (posts.isEmpty) return null;
    final visible = await filterVisiblePosts(
      posts,
      currentUserId: query.userId.trim(),
      followingIds: await _loadFollowingIds(query.userId),
      hiddenPostIds: const <String>{},
      nowMs: DateTime.now().millisecondsSinceEpoch,
      cutoffMs: 0,
      limit: query.limit,
    );
    return visible.isEmpty ? null : visible;
  }

  Future<Set<String>> _loadFollowingIds(String userId) async {
    return VisibilityPolicyService.ensure().loadViewerFollowingIds(
      viewerUserId: userId,
      preferCache: true,
    );
  }

  Future<List<PostsModel>> _fetchVisiblePublicIzBirakPosts({
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final posts = await _postRepository.fetchPublicScheduledIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    if (posts.isEmpty) return const <PostsModel>[];
    final authorMeta = await _userSummaryResolver.resolveMany(
      posts.map((post) => post.userID).toSet().toList(growable: false),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    return posts.where((post) {
      final meta = authorMeta[post.userID];
      if (meta == null) return false;
      final rozet = meta.rozet.trim();
      return rozet.isNotEmpty || meta.isApproved;
    }).toList(growable: false);
  }

  Future<List<PostsModel>> filterVisiblePosts(
    List<PostsModel> items, {
    required String currentUserId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
  }) async {
    if (items.isEmpty) return const <PostsModel>[];
    final normalized = _normalizePosts(items)
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    final authorIds = normalized
        .map((post) => post.userID)
        .where((id) => id.isNotEmpty)
        .toSet();
    final summaries = await _userSummaryResolver.resolveMany(
      authorIds.toList(growable: false),
      preferCache: true,
    );

    final visible = <PostsModel>[];
    final dropLogs = <String>[];
    for (final post in normalized) {
      final reasons = <String>[];
      if (hiddenPostIds.contains(post.docID)) {
        reasons.add('hidden');
      }
      if (post.deletedPost == true) reasons.add('deleted');
      if (post.gizlendi) reasons.add('gizlendi');
      if (post.isUploading) reasons.add('uploading');
      if (reasons.isNotEmpty) {
        if (kDebugMode && dropLogs.length < 12) {
          dropLogs.add('${post.docID}:${reasons.join('+')}');
        }
        continue;
      }
      if (!_isRenderablePost(post)) {
        if (kDebugMode && dropLogs.length < 12) {
          dropLogs.add('${post.docID}:not_renderable');
        }
        continue;
      }
      if (!_isInAgendaWindow(post.timeStamp.toInt(), nowMs, cutoffMs)) {
        if (kDebugMode && dropLogs.length < 12) {
          dropLogs.add('${post.docID}:out_of_window:${post.timeStamp}');
        }
        continue;
      }
      final summary = summaries[post.userID];
      if (summary == null) {
        if (kDebugMode && dropLogs.length < 12) {
          dropLogs.add('${post.docID}:missing_summary:${post.userID}');
        }
        continue;
      }
      if (summary.isDeleted) {
        if (kDebugMode && dropLogs.length < 12) {
          final flags = <String>[];
          if (summary.isDeleted) flags.add('author_deleted');
          dropLogs.add('${post.docID}:${flags.join('+')}:${post.userID}');
        }
        continue;
      }
      final canSeeAuthor = _visibilityPolicy.canViewerSeeAuthorFromSummary(
        authorUserId: post.userID,
        followingIds: followingIds,
        isPrivate: summary.isPrivate,
        isDeleted: summary.isDeleted,
      );
      if (!canSeeAuthor) {
        if (kDebugMode && dropLogs.length < 12) {
          dropLogs.add('${post.docID}:private_not_following:${post.userID}');
        }
        continue;
      }
      if (post.timeStamp > nowMs && post.scheduledAt.toInt() <= 0) {
        if (kDebugMode && dropLogs.length < 12) {
          dropLogs.add('${post.docID}:future_unscheduled:${post.timeStamp}');
        }
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
      if (visible.length >= limit) break;
    }
    if (kDebugMode && dropLogs.isNotEmpty) {
      debugPrint(
        '[FeedFilterDrop] uid=$currentUserId count=${dropLogs.length} '
        'sample=${dropLogs.join(',')}',
      );
    }
    return visible;
  }

  Future<FeedSourcePage> _loadLegacyPage({
    required String currentUserId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required DocumentSnapshot<Map<String, dynamic>>? startAfter,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final page = await _postRepository.fetchAgendaWindowPage(
      cutoffMs: cutoffMs,
      nowMs: nowMs,
      limit: limit,
      startAfter: startAfter,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final visible = await filterVisiblePosts(
      page.items,
      currentUserId: currentUserId,
      followingIds: followingIds,
      hiddenPostIds: hiddenPostIds,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
    );
    return FeedSourcePage(
      items: visible,
      lastDoc: page.lastDoc,
      usesPrimaryFeed: false,
    );
  }

  Future<Map<String, Map<String, dynamic>>> _buildUserMeta(
    List<PostsModel> posts,
  ) async {
    final userIds =
        posts.map((post) => post.userID).where((id) => id.isNotEmpty);
    final summaries = await _userSummaryResolver.resolveMany(
      userIds.toSet().toList(growable: false),
      preferCache: true,
    );
    return summaries.map(
      (key, value) => MapEntry(key, value.toMap()),
    );
  }

  bool _isRenderablePost(PostsModel post) {
    if (!post.hasVideoSignal) return true;
    return post.hasRenderableVideoCard;
  }

  bool _isInAgendaWindow(int timeStamp, int nowMs, int cutoffMs) {
    if (cutoffMs <= 0) return timeStamp <= nowMs || timeStamp > 0;
    return timeStamp >= cutoffMs && timeStamp <= nowMs;
  }

  bool _isEligibleFeedReference(
    UserFeedReference item,
    int nowMs,
    int cutoffMs,
  ) {
    if (item.timeStamp <= 0) return false;
    if (cutoffMs > 0 && item.timeStamp < cutoffMs) return false;
    if (item.expiresAt > 0 && item.expiresAt < nowMs) return false;
    return true;
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

  ScopedSnapshotKey _homeKey(FeedSnapshotQuery query) {
    return ScopedSnapshotKey(
      surfaceKey: _homeSurfaceKey,
      userId: query.userId.trim(),
      scopeId: query.scopeId,
    );
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
