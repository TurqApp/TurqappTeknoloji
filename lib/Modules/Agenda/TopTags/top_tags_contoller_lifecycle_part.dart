part of 'top_tags_contoller_library.dart';

extension _TopTagsControllerLifecyclePart on TopTagsController {
  void handleOnInit() {
    scrollController.addListener(_onScroll);
    getTags();
    fetchAgendaBigData(initial: true);
  }

  void handleOnClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
  }
}
