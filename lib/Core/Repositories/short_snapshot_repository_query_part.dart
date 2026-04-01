part of 'short_snapshot_repository.dart';

Stream<CachedResource<List<PostsModel>>> _openHome(
  ShortSnapshotRepository repository, {
  required String userId,
  required int limit,
  required bool forceSync,
}) {
  final effectiveLimit = ReadBudgetRegistry.resolveShortHomeInitialLimit(limit);
  return repository._homePipeline.open(
    ShortSnapshotQuery(
      userId: userId,
      limit: effectiveLimit,
    ),
    forceSync: forceSync,
  );
}

Future<CachedResource<List<PostsModel>>> _bootstrapHome(
  ShortSnapshotRepository repository, {
  required String userId,
  required int limit,
}) {
  final effectiveLimit = ReadBudgetRegistry.resolveShortHomeInitialLimit(limit);
  final query = ShortSnapshotQuery(
    userId: userId,
    limit: effectiveLimit,
  );
  return repository._coordinator.bootstrap(
    ScopedSnapshotKey(
      surfaceKey: ShortSnapshotRepository._homeSurfaceKey,
      userId: query.userId.trim(),
      scopeId: query.scopeId,
    ),
    loadWarmSnapshot: () => _performLoadWarmSnapshot(repository, query),
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      ShortSnapshotRepository._homeSurfaceKey,
    ),
  );
}

Future<CachedResource<List<PostsModel>>> _loadHome(
  ShortSnapshotRepository repository, {
  required String userId,
  required int limit,
  required bool forceSync,
}) {
  return repository
      .openHome(
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      )
      .last;
}

Future<void> _persistHomeSnapshot(
  ShortSnapshotRepository repository, {
  required String userId,
  required List<PostsModel> posts,
  required int limit,
  required CachedResourceSource source,
  DateTime? snapshotAt,
}) async {
  final effectiveLimit = ReadBudgetRegistry.resolveShortHomeInitialLimit(limit);
  final normalized = repository
      ._normalizePosts(posts)
      .take(effectiveLimit)
      .toList(growable: false);
  final key = ScopedSnapshotKey(
    surfaceKey: ShortSnapshotRepository._homeSurfaceKey,
    userId: userId.trim(),
    scopeId: ShortSnapshotQuery(
      userId: userId,
      limit: effectiveLimit,
    ).scopeId,
  );
  if (normalized.isEmpty) {
    await Future.wait(<Future<void>>[
      repository._memoryStore.clearScope(key),
      repository._snapshotStore.clearScope(key),
      repository._warmLaunchPool.clearKind(IndexPoolKind.shortFullscreen),
    ]);
    return;
  }
  final record = ScopedSnapshotRecord<List<PostsModel>>(
    data: normalized,
    snapshotAt: snapshotAt ?? DateTime.now(),
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      ShortSnapshotRepository._homeSurfaceKey,
    ),
    generationId: 'manual:${DateTime.now().millisecondsSinceEpoch}',
    source: source,
  );
  await Future.wait(<Future<void>>[
    repository._memoryStore.write(key, record),
    repository._snapshotStore.write(key, record),
    repository._warmLaunchPool
        .savePosts(IndexPoolKind.shortFullscreen, normalized),
  ]);
}

Future<List<PostsModel>> _performFetchEligibleSnapshot(
  ShortSnapshotRepository repository,
  ShortSnapshotQuery query,
) async {
  final followingIds = await repository._loadFollowingIds(query.userId);
  final me = query.userId.trim();
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
  final collected = <PostsModel>[];
  final seen = <String>{};

  for (int attempt = 0;
      attempt < ShortSnapshotRepository._maxPageSkips;
      attempt++) {
    final page = await repository._shortRepository.fetchReadyPage(
      startAfter: cursor,
      pageSize: query.effectiveLimit,
      nowMs: nowMs,
    );
    if (page.posts.isEmpty) break;

    final eligible = await repository._filterEligiblePosts(
      page.posts,
      currentUserId: me,
      followingIds: followingIds,
    );
    for (final post in eligible) {
      if (seen.add(post.docID)) {
        collected.add(post);
      }
    }
    if (collected.length >= query.effectiveLimit) break;
    if (!page.hasMore || page.lastDoc == null) break;
    cursor = page.lastDoc;
  }

  return collected.take(query.effectiveLimit).toList(growable: false);
}

Future<List<PostsModel>?> _performLoadWarmSnapshot(
  ShortSnapshotRepository repository,
  ShortSnapshotQuery query,
) async {
  final posts = await repository._warmLaunchPool.loadPosts(
    IndexPoolKind.shortFullscreen,
    limit: query.effectiveLimit,
    allowStale: false,
  );
  if (posts.isEmpty) return null;
  final eligible = await repository._filterEligiblePosts(
    posts,
    currentUserId: query.userId.trim(),
    followingIds: await repository._loadFollowingIds(query.userId),
  );
  final normalized =
      eligible.take(query.effectiveLimit).toList(growable: false);
  if (normalized.length != posts.length) {
    final validIds = normalized.map((post) => post.docID).toSet();
    final invalidIds = posts
        .where((post) => !validIds.contains(post.docID))
        .map((post) => post.docID)
        .toList(growable: false);
    if (invalidIds.isNotEmpty) {
      await repository._warmLaunchPool.removePosts(
        IndexPoolKind.shortFullscreen,
        invalidIds,
      );
    }
  }
  return normalized.isEmpty ? null : normalized;
}
