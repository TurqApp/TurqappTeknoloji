part of 'feed_snapshot_repository.dart';

extension _FeedSnapshotRepositoryCodecX on FeedSnapshotRepository {
  ScopedSnapshotKey _homeKey(FeedSnapshotQuery query) {
    return ScopedSnapshotKey(
      surfaceKey: FeedSnapshotRepository._homeSurfaceKey,
      userId: query.userId.trim(),
      scopeId: query.scopeId,
    );
  }

  Map<String, dynamic> _encodePosts(List<PostsModel> posts) {
    return <String, dynamic>{
      'items': posts
          .map((post) => <String, dynamic>{
                'docID': post.docID,
                ...post.toMap(),
              })
          .toList(growable: false),
    };
  }

  List<PostsModel> _decodePosts(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    final decoded = rawItems
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
          final docId = (item.remove('docID') ?? '').toString();
          return PostsModel.fromMap(item, docId);
        })
        .where((post) => post.docID.isNotEmpty)
        .toList(growable: false);
    return _normalizePosts(decoded);
  }
}
