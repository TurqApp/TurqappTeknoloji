part of 'top_tags_repository_parts.dart';

extension TopTagsRepositoryRuntimePart on TopTagsRepository {
  Future<List<HashtagModel>?> readTrendingTagsCache({
    int resultLimit = 30,
  }) async {
    final memory = _readMemory(limit: resultLimit);
    if (memory != null) return memory;
    final disk = await _readPrefs(limit: resultLimit);
    if (disk != null) {
      _memory = disk;
      _memoryAt = DateTime.now();
      return disk;
    }
    return null;
  }

  Future<List<HashtagModel>> fetchTrendingTags({
    int resultLimit = 30,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && preferCache) {
      final cached = await readTrendingTagsCache(
        resultLimit: resultLimit,
      );
      if (cached != null) return cached;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final snap = await _db
        .collection("tags")
        .orderBy("count", descending: true)
        .limit(200)
        .get();

    final list = <HashtagModel>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final rawTag = doc.id.toString().trim();
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
    final result = list.take(resultLimit).toList(growable: false);
    await _store(result);
    return result;
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
    int limit = 15,
    bool reset = false,
  }) =>
      _TopTagsRepositoryCacheX(this).fetchImagePostsPage(
        limit: limit,
        reset: reset,
      );
}
