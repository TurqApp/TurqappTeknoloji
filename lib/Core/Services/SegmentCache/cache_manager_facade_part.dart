part of 'cache_manager.dart';

SegmentCacheManager? maybeFindSegmentCacheManager() {
  final isRegistered = Get.isRegistered<SegmentCacheManager>();
  if (!isRegistered) return null;
  return Get.find<SegmentCacheManager>();
}

SegmentCacheManager ensureSegmentCacheManager() {
  final existing = maybeFindSegmentCacheManager();
  if (existing != null) return existing;
  return Get.put(SegmentCacheManager(), permanent: true);
}

extension SegmentCacheManagerFacadePart on SegmentCacheManager {
  Future<void> init() => _SegmentCacheManagerRuntimeX(this).init();

  bool get isReady => _SegmentCacheManagerRuntimeX(this).isReady;
  String get cacheDir => _SegmentCacheManagerRuntimeX(this).cacheDir;
  int get entryCount => _SegmentCacheManagerRuntimeX(this).entryCount;
  int get totalSizeBytes => _SegmentCacheManagerRuntimeX(this).totalSizeBytes;
  int get metadataUsageBytes =>
      _SegmentCacheManagerRuntimeX(this).metadataUsageBytes;
  int get totalTrackedUsageBytes =>
      _SegmentCacheManagerRuntimeX(this).totalTrackedUsageBytes;
  int get cachedVideoCount =>
      _SegmentCacheManagerRuntimeX(this).cachedVideoCount;
  int get totalSegmentCount =>
      _SegmentCacheManagerRuntimeX(this).totalSegmentCount;
  List<String> get recentlyPlayed =>
      _SegmentCacheManagerRuntimeX(this).recentlyPlayed;
  int get softLimitBytes => _SegmentCacheManagerRuntimeX(this).softLimitBytes;
  int get hardLimitBytes => _SegmentCacheManagerRuntimeX(this).hardLimitBytes;

  File? getSegmentFile(String docID, String segmentKey) =>
      _SegmentCacheManagerRuntimeX(this).getSegmentFile(docID, segmentKey);

  File? getPlaylistFile(String relativePath) =>
      _SegmentCacheManagerRuntimeX(this).getPlaylistFile(relativePath);

  VideoCacheEntry? getEntry(String docID) =>
      _SegmentCacheManagerRuntimeX(this).getEntry(docID);

  void cachePostCards(Iterable<PostsModel> posts) =>
      _SegmentCacheManagerRuntimeX(this).cachePostCards(posts);

  void cacheHlsEntry(String docID, String masterPlaylistUrl) =>
      _SegmentCacheManagerRuntimeX(this).cacheHlsEntry(
        docID,
        masterPlaylistUrl,
      );

  List<String> getOfflineReadyDocIds({int limit = 0}) {
    final entries = _index.entries.values
        .where((entry) => entry.isFullyCached)
        .toList(growable: false)
      ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
    final docIds = entries
        .map((entry) => entry.docID.trim())
        .where((docId) => docId.isNotEmpty)
        .toList(growable: false);
    if (limit <= 0 || docIds.length <= limit) {
      return docIds;
    }
    return docIds.take(limit).toList(growable: false);
  }

  List<PostsModel> getOfflineReadyPosts({int limit = 0}) {
    final entries = _index.entries.values
        .where((entry) => entry.isFullyCached)
        .toList(growable: false)
      ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
    final posts = entries
        .map((entry) => entry.cachedPostModel)
        .whereType<PostsModel>()
        .where((post) => post.docID.trim().isNotEmpty)
        .toList(growable: false);
    if (limit <= 0 || posts.length <= limit) {
      return posts;
    }
    return posts.take(limit).toList(growable: false);
  }

  void markPlaying(String docID) =>
      _SegmentCacheManagerRuntimeX(this).markPlaying(docID);

  void updateWatchProgress(String docID, double progress) =>
      _SegmentCacheManagerRuntimeX(this).updateWatchProgress(docID, progress);

  void touchEntry(String docID) =>
      _SegmentCacheManagerRuntimeX(this).touchEntry(docID);

  void touchUserEntry(String docID) =>
      _SegmentCacheManagerRuntimeX(this).touchUserEntry(docID);

  Future<void> evictIfNeeded({int? targetBytes}) async {
    final target = targetBytes ?? softLimitBytes;
    while (_index.totalSizeBytes > target) {
      if (cachedVideoCount <= ContentPolicy.minGlobalCachedVideos) {
        break;
      }
      final candidate = _findEvictionCandidate(preferLowQuality: true);
      if (candidate == null) break;
      await _evictEntry(candidate);
    }
  }

  Future<void> _handleSegmentCacheManagerOnClose() async {
    await _SegmentCacheManagerRuntimeX(this).disposeRuntime();
  }
}
