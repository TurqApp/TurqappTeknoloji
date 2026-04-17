part of 'short_snapshot_repository.dart';

String _performTrimmedSnapshotDocId(Object? value) =>
    (value ?? '').toString().trim();

Future<Set<String>> _performLoadFollowingIds(
  ShortSnapshotRepository repository,
  String userId,
) {
  return VisibilityPolicyService.ensure().loadViewerFollowingIds(
    viewerUserId: userId,
    preferCache: true,
  );
}

Future<List<PostsModel>> _performFilterEligiblePosts(
  ShortSnapshotRepository repository,
  List<PostsModel> posts, {
  required String currentUserId,
  required Set<String> followingIds,
}) async {
  if (posts.isEmpty) return const <PostsModel>[];
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final normalized = repository
      ._normalizePosts(posts)
      .where((post) => post.timeStamp <= nowMs)
      .where((post) => !post.deletedPost)
      .where((post) => !post.arsiv)
      .where((post) => !post.gizlendi)
      .where((post) => post.hasPlayableVideo)
      .toList(growable: false);
  if (normalized.isEmpty) return const <PostsModel>[];

  final warmFeedVisibleVideoDocIds =
      await loadWarmFeedVisibleVideoDocIdsForShort(currentUserId);
  final authorIds = normalized
      .map((post) => post.userID)
      .where((id) => id.isNotEmpty)
      .toSet();
  final summaries = await repository._userSummaryResolver.resolveMany(
    authorIds.toList(growable: false),
    preferCache: true,
  );

  final visible = <PostsModel>[];
  for (final post in normalized) {
    final summary = summaries[post.userID];
    if (summary?.isDeleted == true) {
      continue;
    }
    final rozet = post.rozet.isNotEmpty ? post.rozet : (summary?.rozet ?? '');
    final isApproved = summary?.isApproved == true;
    if (!isDiscoveryPublicAuthor(
      rozet: rozet,
      isApproved: isApproved,
    )) {
      continue;
    }
    visible.add(
      post.copyWith(
        authorNickname: post.authorNickname.isNotEmpty
            ? post.authorNickname
            : (summary?.nickname ?? ''),
        authorDisplayName: post.authorDisplayName.isNotEmpty
            ? post.authorDisplayName
            : (summary?.displayName ?? ''),
        authorAvatarUrl: post.authorAvatarUrl.isNotEmpty
            ? post.authorAvatarUrl
            : (summary?.avatarUrl ?? ''),
        rozet: rozet,
      ),
    );
  }
  final deduped =
      excludeFeedVisibleShortConflicts(visible, warmFeedVisibleVideoDocIds);
  final rewatchFiltered = await excludePersistedShortRewatchPosts(deduped);
  repository._invariantGuard.assertNotEmptyAfterRefresh(
    surface: 'short',
    invariantKey: 'eligible_visible_after_filter',
    hadSnapshot: normalized.isNotEmpty,
    previousCount: normalized.length,
    nextCount: rewatchFiltered.length,
    payload: <String, dynamic>{
      'currentUserId': currentUserId,
      'followingCount': followingIds.length,
    },
  );
  return rewatchFiltered;
}

List<PostsModel> _performNormalizePosts(List<PostsModel> posts) {
  final seen = <String>{};
  final normalized = <PostsModel>[];
  for (final post in posts) {
    if (post.docID.isEmpty || !seen.add(post.docID)) continue;
    normalized.add(post);
  }
  return normalized;
}

Map<String, dynamic> _performEncodePosts(List<PostsModel> posts) {
  final payload = <String, dynamic>{
    'items': posts
        .map((post) => <String, dynamic>{
              'docID': post.docID,
              ...post.toMap(),
            })
        .toList(growable: false),
  };
  final posterHints = TurqImageCacheManager.buildPosterHintsForPosts(posts);
  if (posterHints.isNotEmpty) {
    payload[TurqImageCacheManager.startupPosterHintsKey] = posterHints;
  }
  return payload;
}

List<PostsModel> _performDecodePosts(Map<String, dynamic> json) {
  TurqImageCacheManager.hydratePosterHintsFromPayload(json);
  final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
  return rawItems
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
        final docId = _performTrimmedSnapshotDocId(item.remove('docID'));
        return PostsModel.fromMap(item, docId);
      })
      .where((post) => post.docID.isNotEmpty)
      .toList(growable: false);
}
