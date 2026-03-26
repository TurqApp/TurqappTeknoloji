part of 'photo_shorts_controller.dart';

class PhotoShortsController extends GetxController {
  var list = <PostsModel>[].obs;
  final PostRepository _postRepository = PostRepository.ensure();

  Future<void> addToList(List<PostsModel> photoList) async {
    list.assignAll(photoList);
  }

  Future<void> updatePost(String docID) async {
    final posts = await _postRepository.fetchPostsByIds([docID]);
    final updatedPost = posts[docID];
    if (updatedPost == null) return;

    final idx = list.indexWhere((e) => e.docID == docID);
    if (idx != -1) {
      list[idx] = updatedPost;
      list.refresh();
    }
  }
}
