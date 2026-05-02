part of 'top_tags_repository_parts.dart';

extension TopTagsRepositoryRuntimePart on TopTagsRepository {
  static const Duration _authReadyTimeout = Duration(milliseconds: 1600);

  Future<void> _ensureTopTagsAccessReady({
    bool forceTokenRefresh = false,
  }) async {
    final currentUser = CurrentUserService.instance;
    if (!forceTokenRefresh && !currentUser.hasAuthUser) {
      return;
    }
    await currentUser.ensureAuthReady(
      waitForAuthState: true,
      forceTokenRefresh: forceTokenRefresh,
      timeout: _authReadyTimeout,
      recordTimeoutFailure: false,
    );
  }

  Future<List<HashtagModel>> _loadTrendingTagsFromFirestore({
    required int resultLimit,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final snap = await _db
        .collection("tags")
        .orderBy("count", descending: true)
        .limit(ReadBudgetRegistry.topTagsRepositoryFetchLimit)
        .get();

    final list = <HashtagModel>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final rawTag = doc.id.toString().trim();
      if (rawTag.startsWith("#")) continue;
      final tag = rawTag.replaceFirst("#", "");
      if (tag.isEmpty) continue;

      final count = ((data["count"] ?? data["counter"] ?? 0) as num).toInt();
      final threshold =
          ((data["trendThreshold"] ?? _topTagsDefaultTrendThreshold) as num)
              .toInt();
      if (count < threshold || count <= 0) continue;

      final windowHours =
          ((data["trendWindowHours"] ?? _topTagsDefaultTrendWindowHours) as num)
              .toInt();
      final windowMs = Duration(
        hours: windowHours <= 0 ? _topTagsDefaultTrendWindowHours : windowHours,
      ).inMilliseconds;
      final rawLastSeenTs = ((data["lastSeenTs"] as num?)?.toInt()) ??
          ((data["lastSeenAt"] as num?)?.toInt()) ??
          0;
      final effectiveLastSeenTs =
          _resolveLastSeenActivityTs(rawLastSeenTs, windowMs, nowMs);
      if (effectiveLastSeenTs <= 0) continue;
      if ((nowMs - effectiveLastSeenTs) > windowMs) continue;

      list.add(
        HashtagModel(
          tag,
          count,
          hasHashtag: rawTag.startsWith("#") ||
              (((data["hashtagCount"] ?? 0) as num) > 0),
          lastSeenTs: effectiveLastSeenTs,
        ),
      );
    }

    list.sort((a, b) {
      final countCmp = b.count.compareTo(a.count);
      if (countCmp != 0) return countCmp;
      return (b.lastSeenTs ?? 0).compareTo(a.lastSeenTs ?? 0);
    });
    return list.take(resultLimit).toList(growable: false);
  }

  Future<List<HashtagModel>?> readTrendingTagsCache({
    int resultLimit = ReadBudgetRegistry.topTagsTrendingResultLimit,
  }) async {
    final memory = _readMemory(limit: resultLimit);
    if (memory != null) return memory;
    final disk = await _readPrefs(limit: resultLimit);
    if (disk != null) {
      _memory = List<HashtagModel>.from(disk);
      _memoryAt = DateTime.now();
      return List<HashtagModel>.from(disk);
    }
    return null;
  }

  Future<List<HashtagModel>> fetchTrendingTags({
    int resultLimit = ReadBudgetRegistry.topTagsTrendingResultLimit,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    List<HashtagModel>? cachedForFallback;
    if (!forceRefresh && preferCache) {
      final cached = await readTrendingTagsCache(
        resultLimit: resultLimit,
      );
      if (cached != null) return cached;
    } else {
      cachedForFallback = await readTrendingTagsCache(
        resultLimit: resultLimit,
      );
    }

    try {
      await _ensureTopTagsAccessReady();
      final result = await _loadTrendingTagsFromFirestore(
        resultLimit: resultLimit,
      );
      if (result.isEmpty &&
          cachedForFallback != null &&
          cachedForFallback.isNotEmpty) {
        return cachedForFallback;
      }
      await _store(result);
      return result;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        await _ensureTopTagsAccessReady(forceTokenRefresh: true);
        try {
          final result = await _loadTrendingTagsFromFirestore(
            resultLimit: resultLimit,
          );
          if (result.isEmpty &&
              cachedForFallback != null &&
              cachedForFallback.isNotEmpty) {
            return cachedForFallback;
          }
          await _store(result);
          return result;
        } on FirebaseException {
          if (cachedForFallback != null && cachedForFallback.isNotEmpty) {
            return cachedForFallback;
          }
          return const <HashtagModel>[];
        }
      }
      if (cachedForFallback != null && cachedForFallback.isNotEmpty) {
        return cachedForFallback;
      }
      rethrow;
    } catch (_) {
      if (cachedForFallback != null && cachedForFallback.isNotEmpty) {
        return cachedForFallback;
      }
      rethrow;
    }
  }
}

TopTagsRepository? maybeFindTopTagsRepository() =>
    Get.isRegistered<TopTagsRepository>()
        ? Get.find<TopTagsRepository>()
        : null;

TopTagsRepository ensureTopTagsRepository() =>
    maybeFindTopTagsRepository() ??
    Get.put(TopTagsRepository(), permanent: true);

extension TopTagsRepositoryFacadePart on TopTagsRepository {
  Future<List<PostsModel>> fetchImagePostsPage({
    int limit = ReadBudgetRegistry.topTagsFeedPostLimit,
    bool reset = false,
  }) =>
      _TopTagsRepositoryCacheX(this).fetchImagePostsPage(
        limit: limit,
        reset: reset,
      );
}
