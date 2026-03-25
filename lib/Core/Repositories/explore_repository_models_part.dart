part of 'explore_repository.dart';

class ExploreQueryPage {
  const ExploreQueryPage({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}
