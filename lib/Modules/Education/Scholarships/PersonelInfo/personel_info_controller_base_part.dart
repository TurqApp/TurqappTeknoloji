part of 'personel_info_controller.dart';

abstract class _PersonelInfoControllerBase extends GetxController
    with GetTickerProviderStateMixin {
  final _state = _PersonelInfoControllerState();

  @override
  void onInit() {
    super.onInit();
    final controller = this as PersonelInfoController;
    controller.loadCitiesAndTowns();
    controller.fetchData();
    controller.initializeFieldConfigs();
    controller.initializeAnimationControllers();
  }

  @override
  void onClose() {
    (this as PersonelInfoController).disposeAnimationControllers();
    super.onClose();
  }
}
