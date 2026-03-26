part of 'photo_shorts_controller.dart';

class PhotoShortsController extends GetxController {
  static PhotoShortsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PhotoShortsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static PhotoShortsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<PhotoShortsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PhotoShortsController>(tag: tag);
  }

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
