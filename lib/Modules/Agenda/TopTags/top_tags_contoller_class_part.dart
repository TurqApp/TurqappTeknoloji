part of 'top_tags_contoller.dart';

class TopTagsController extends GetxController {
  final TopTagsRepository _repo;
  TopTagsController({TopTagsRepository? repository})
      : _repo = repository ?? ensureTopTagsRepository();
  final _state = _TopTagsControllerState();

  @override
  void onInit() {
    super.onInit();
    _TopTagsControllerLifecyclePart(this).handleOnInit();
  }

  @override
  void onClose() {
    _TopTagsControllerLifecyclePart(this).handleOnClose();
    super.onClose();
  }
}
