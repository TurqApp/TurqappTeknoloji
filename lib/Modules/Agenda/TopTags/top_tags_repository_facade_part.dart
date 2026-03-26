part of 'top_tags_repository.dart';

extension TopTagsRepositoryFacadePart on TopTagsRepository {
  Future<void> _store(List<HashtagModel> items) =>
      _TopTagsRepositoryCacheX(this)._store(items);

  List<HashtagModel>? _readMemory({required int limit}) =>
      _TopTagsRepositoryCacheX(this)._readMemory(limit: limit);

  Future<List<HashtagModel>?> _readPrefs({required int limit}) =>
      _TopTagsRepositoryCacheX(this)._readPrefs(limit: limit);

  int _resolveLastSeenActivityTs(int rawLastSeenTs, int windowMs, int nowMs) =>
      _TopTagsRepositoryCacheX(this)
          ._resolveLastSeenActivityTs(rawLastSeenTs, windowMs, nowMs);

  Future<List<PostsModel>> fetchImagePostsPage({
    int limit = 15,
    bool reset = false,
  }) =>
      _TopTagsRepositoryCacheX(this).fetchImagePostsPage(
        limit: limit,
        reset: reset,
      );
}
