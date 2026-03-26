part of 'top_tags_contoller_library.dart';

abstract class _TopTagsControllerBase extends GetxController {
  _TopTagsControllerBase({TopTagsRepository? repository})
      : _repo = repository ?? ensureTopTagsRepository();

  final TopTagsRepository _repo;
  final _state = _TopTagsControllerState();

  @override
  void onInit() {
    super.onInit();
    _TopTagsControllerLifecyclePart(this as TopTagsController).handleOnInit();
  }

  @override
  void onClose() {
    _TopTagsControllerLifecyclePart(this as TopTagsController).handleOnClose();
    super.onClose();
  }
}
