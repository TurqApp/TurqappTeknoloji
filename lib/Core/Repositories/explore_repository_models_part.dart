part of 'explore_repository.dart';

class ExploreQueryPage {
  const ExploreQueryPage(this.items, this.lastDoc, this.hasMore);

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}
