part of 'tag_posts_controller.dart';

class TagPostsController extends GetxController {
  static String _normalizeTag(String tag) => tag.trim();
  static String? _activeTag;

  final _TagPostsControllerState _state;

  TagPostsController({
    required String tag,
    required String controllerTag,
    TagPostsRepository? repository,
  }) : _state = _TagPostsControllerState(
          tag: tag,
          controllerTag: controllerTag,
          repository: repository,
        );

  @override
  void onClose() {
    _handleTagPostsClose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    _handleTagPostsInit();
  }
}
