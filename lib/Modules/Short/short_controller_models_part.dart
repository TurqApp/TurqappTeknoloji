part of 'short_controller.dart';

enum _ShortSessionSourceMode {
  unresolved,
  wifiLive,
  mobileCacheOnly,
  mobileNetworkFallback,
}

enum _CacheTier { hot, warm }

class _ShortPageResult {
  const _ShortPageResult(
    this.posts,
    this.lastDoc,
    this.hasMore, {
    this.postsPreplanned = false,
  });

  final List<PostsModel> posts;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  final bool postsPreplanned;
}
