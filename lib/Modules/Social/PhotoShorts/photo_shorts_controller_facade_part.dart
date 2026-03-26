part of 'photo_shorts_controller.dart';

PhotoShortsController ensurePhotoShortsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindPhotoShortsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    PhotoShortsController(),
    tag: tag,
    permanent: permanent,
  );
}

PhotoShortsController? maybeFindPhotoShortsController({String? tag}) {
  final isRegistered = Get.isRegistered<PhotoShortsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<PhotoShortsController>(tag: tag);
}

extension PhotoShortsControllerFacadePart on PhotoShortsController {
  Future<void> addToList(List<PostsModel> photoList) async {
    list.assignAll(photoList);
  }

  Future<void> updatePost(String docID) async {
    final posts = _postRepository.fetchPostsByIds([docID]);
    final updatedPost = (await posts)[docID];
    if (updatedPost == null) return;

    final idx = list.indexWhere((e) => e.docID == docID);
    if (idx != -1) {
      list[idx] = updatedPost;
      list.refresh();
    }
  }
}
