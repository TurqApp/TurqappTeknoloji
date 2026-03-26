part of 'top_tags_repository_parts.dart';

TopTagsRepository? maybeFindTopTagsRepository() =>
    Get.isRegistered<TopTagsRepository>()
        ? Get.find<TopTagsRepository>()
        : null;

TopTagsRepository ensureTopTagsRepository() =>
    maybeFindTopTagsRepository() ??
    Get.put(TopTagsRepository(), permanent: true);

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
