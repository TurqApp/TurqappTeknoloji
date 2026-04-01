part of 'short_repository.dart';

class ShortPageResult {
  const ShortPageResult(this.posts, this.lastDoc, this.hasMore);

  final List<PostsModel> posts;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}
