part of 'antreman_controller.dart';

class AntremanController extends GetxController
    with _AntremanControllerBasePart {
  @override
  void onInit() {
    super.onInit();
    loadMainCategory();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
