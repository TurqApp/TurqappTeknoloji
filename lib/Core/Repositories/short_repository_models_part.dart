part of 'short_repository.dart';

class ShortPageResult {
  const ShortPageResult({
    required this.posts,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<PostsModel> posts;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}
