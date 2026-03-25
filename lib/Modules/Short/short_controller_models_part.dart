part of 'short_controller.dart';

enum _CacheTier { hot, warm }

class _ShortPageResult {
  final List<PostsModel> posts;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  const _ShortPageResult({
    required this.posts,
    required this.lastDoc,
    required this.hasMore,
  });
}
