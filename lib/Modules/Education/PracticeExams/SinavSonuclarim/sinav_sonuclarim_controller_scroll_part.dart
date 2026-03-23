part of 'sinav_sonuclarim_controller.dart';

extension SinavSonuclarimControllerScrollPart on SinavSonuclarimController {
  void _setupScrollControllerImpl() {
    scrollController.addListener(() {
      final currentOffset = scrollController.position.pixels;

      if (currentOffset > _previousOffset) {
        if (ustBar.value) ustBar.value = false;
      } else if (currentOffset < _previousOffset) {
        if (!ustBar.value) ustBar.value = true;
      }

      _previousOffset = currentOffset;
    });
  }
}
