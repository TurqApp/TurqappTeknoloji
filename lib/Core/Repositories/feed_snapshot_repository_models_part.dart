part of 'feed_snapshot_repository.dart';

class FeedSnapshotQuery {
  const FeedSnapshotQuery({
    required this.userId,
    this.limit = 30,
    this.scopeTag = 'home',
  });

  final String userId;
  final int limit;
  final String scopeTag;

  String get scopeId => <String>[
        'limit=$limit',
        'scope=${scopeTag.trim()}',
      ].join('|');
}

class FeedSourcePage {
  const FeedSourcePage({
    required this.items,
    required this.lastDoc,
    required this.usesPrimaryFeed,
  });

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool usesPrimaryFeed;
}
