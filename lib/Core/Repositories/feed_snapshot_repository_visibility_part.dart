part of 'feed_snapshot_repository.dart';

extension _FeedSnapshotRepositoryVisibilityPart on FeedSnapshotRepository {
  Future<List<PostsModel>> filterVisiblePosts(
    List<PostsModel> items, {
    required String currentUserId,
    required Set<String> followingIds,
    required Set<String> hiddenPostIds,
    required int nowMs,
    required int cutoffMs,
    required int limit,
    bool summaryCacheOnly = false,
    bool refreshNonPublicCachedSummaries = true,
  }) async {
    if (items.isEmpty) return const <PostsModel>[];
    final normalized = _normalizePosts(items);
    final authorIds = normalized
        .map((post) => post.userID)
        .where((id) => id.isNotEmpty)
        .toSet();
    final summaries = await _loadDiscoverySummaries(
      authorIds: authorIds,
      currentUserId: currentUserId,
      followingIds: followingIds,
      cacheOnly: summaryCacheOnly,
      refreshNonPublicCachedSummaries: refreshNonPublicCachedSummaries,
    );

    final visible = <PostsModel>[];
    final dropLogs = <String>[];
    for (final post in normalized) {
      final reasons = <String>[];
      if (post.isFloodMember) {
        reasons.add('flood_child');
      }
      if (hiddenPostIds.contains(post.docID)) {
        reasons.add('hidden');
      }
      if (post.deletedPost == true) reasons.add('deleted');
      if (post.gizlendi) reasons.add('gizlendi');
      if (post.shouldHideWhileUploading) {
        if (post.isUploading) reasons.add('uploading');
        if (post.isCompletelyEmptyPost) reasons.add('empty_content');
      }
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
      final canSeeAuthor =
          _visibilityPolicy.canViewerSeeDiscoveryAuthorFromSummary(
        authorUserId: post.userID,
        followingIds: followingIds,
        rozet: summary.rozet,
        isApproved: summary.isApproved,
        isDeleted: summary.isDeleted,
      );
      if (!canSeeAuthor) {
        if (kDebugMode && dropLogs.length < 12) {
          dropLogs.add('${post.docID}:not_following_unbadged:${post.userID}');
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

  Future<Map<String, UserSummary>> _loadDiscoverySummaries({
    required Set<String> authorIds,
    required String currentUserId,
    required Set<String> followingIds,
    required bool cacheOnly,
    required bool refreshNonPublicCachedSummaries,
  }) async {
    if (authorIds.isEmpty) return const <String, UserSummary>{};
    final startedAt = DateTime.now();
    final cached = await _userSummaryResolver.resolveMany(
      authorIds.toList(growable: false),
      preferCache: true,
      cacheOnly: cacheOnly,
    );
    if (cacheOnly) {
      debugPrint(
        '[FeedSnapshotStep] end:load_discovery_summaries '
        'elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} '
        'cacheOnly=true authorCount=${authorIds.length} refreshCount=0',
      );
      return cached;
    }
    final viewerUid = currentUserId.trim();
    final refreshIds = authorIds.where((authorId) {
      final uid = authorId.trim();
      if (uid.isEmpty) return false;
      if (viewerUid.isNotEmpty && uid == viewerUid) return false;
      if (followingIds.contains(uid)) return false;
      final summary = cached[uid];
      if (summary == null) return true;
      if (!refreshNonPublicCachedSummaries) return false;
      if (summary.isDeleted) return false;
      return !isDiscoveryPublicAuthor(
        rozet: summary.rozet,
        isApproved: summary.isApproved,
      );
    }).toList(growable: false);
    if (refreshIds.isEmpty) {
      debugPrint(
        '[FeedSnapshotStep] end:load_discovery_summaries '
        'elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} '
        'cacheOnly=false authorCount=${authorIds.length} refreshCount=0',
      );
      return cached;
    }

    final fresh = await _userSummaryResolver.resolveMany(
      refreshIds,
      preferCache: false,
    );
    final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    debugPrint(
      '[FeedSnapshotStep] end:load_discovery_summaries '
      'elapsedMs=$elapsedMs cacheOnly=false authorCount=${authorIds.length} '
      'refreshCount=${refreshIds.length} freshCount=${fresh.length}',
    );
    if (fresh.isEmpty) return cached;
    return <String, UserSummary>{...cached, ...fresh};
  }

  bool _isRenderablePost(PostsModel post) {
    if (post.isCompletelyEmptyPost) return false;
    if (!post.hasVideoSignal) return true;
    return post.hasPlayableVideo;
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

  bool _shouldDropIntegrationSeedPost(PostsModel post) {
    if (IntegrationTestMode.enabled) return false;
    final docId = post.docID.trim();
    if (docId.startsWith('it_seed_')) return true;
    final userId = post.userID.trim();
    return userId.startsWith('it_seed_');
  }

  List<PostsModel> _normalizePosts(List<PostsModel> posts) {
    final seen = <String>{};
    final normalized = <PostsModel>[];
    for (final post in posts) {
      if (_shouldDropIntegrationSeedPost(post)) continue;
      if (post.docID.isEmpty || !seen.add(post.docID)) continue;
      normalized.add(post);
    }
    return normalized;
  }
}
