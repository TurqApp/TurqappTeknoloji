part of 'tests_controller_library.dart';

extension TestsControllerScrollPart on TestsController {
  void _bindScrollControl() {
    scrollController.addListener(() {
      final currentOffset = scrollController.position.pixels;

      if (currentOffset > _previousOffset.value) {
        if (showButtons.value) {
          showButtons.value = false;
        }
        ustBar.value = false;
      } else if (currentOffset < _previousOffset.value) {
        if (showButtons.value) {
          showButtons.value = false;
        }
        ustBar.value = true;
      }

      if (currentOffset >= scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore.value &&
          hasMore.value) {
        loadMore();
      }

      scrollOffset.value = currentOffset;
      _previousOffset.value = currentOffset;
    });
  }
}
