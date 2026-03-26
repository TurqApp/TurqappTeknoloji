part of 'top_tags_repository.dart';

extension TopTagsRepositoryFacadePart on TopTagsRepository {
  Future<List<PostsModel>> fetchImagePostsPage({
    int limit = 15,
    bool reset = false,
  }) =>
      _TopTagsRepositoryCacheX(this).fetchImagePostsPage(
        limit: limit,
        reset: reset,
      );
}
