part of 'antreman_controller.dart';

void _antremanInit(AntremanController controller) {
  controller.loadMainCategory();
}

void _antremanClose(AntremanController controller) {
  controller._searchDebounce?.cancel();
}
