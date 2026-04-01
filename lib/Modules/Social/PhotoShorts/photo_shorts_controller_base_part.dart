part of 'photo_shorts_controller.dart';

abstract class _PhotoShortsControllerBase extends GetxController {
  final RxList<PostsModel> list = <PostsModel>[].obs;
  final PostRepository _postRepository = PostRepository.ensure();
}
