part of 'tag_posts_controller.dart';

abstract class _TagPostsControllerBase extends GetxController {
  _TagPostsControllerBase({
    required String tag,
    required String controllerTag,
    TagPostsRepository? repository,
  }) : _state = _TagPostsControllerState(
          tag: tag,
          controllerTag: controllerTag,
          repository: repository,
        );

  final _TagPostsControllerState _state;

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
