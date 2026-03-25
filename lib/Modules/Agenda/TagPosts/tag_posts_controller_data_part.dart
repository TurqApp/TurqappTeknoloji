part of 'tag_posts_controller.dart';

extension TagPostsControllerDataPart on TagPostsController {
  Future<void> getPosts() async {
    final fetchedPosts = await _repo.fetchByTag(tag);
    fetchedPosts.shuffle();
    list.assignAll(fetchedPosts);
  }
}
