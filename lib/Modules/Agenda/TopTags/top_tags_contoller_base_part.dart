part of 'top_tags_contoller_library.dart';

class TopTagsController extends _TopTagsControllerBase {
  TopTagsController({TopTagsRepository? repository})
      : super(repository: repository);
}

abstract class _TopTagsControllerBase extends GetxController {
  _TopTagsControllerBase({TopTagsRepository? repository})
      : _repo = repository ?? ensureTopTagsRepository();

  final TopTagsRepository _repo;
  final _state = _TopTagsControllerState();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    getTags();
    fetchAgendaBigData(initial: true);
  }

  @override
  void onClose() {
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.onClose();
  }
}
