part of 'personel_info_controller.dart';

class PersonelInfoController extends GetxController
    with GetTickerProviderStateMixin {
  final _state = _PersonelInfoControllerState();

  @override
  void onInit() {
    super.onInit();
    loadCitiesAndTowns();
    fetchData();
    initializeFieldConfigs();
    initializeAnimationControllers();
  }

  @override
  void onClose() {
    disposeAnimationControllers();
    super.onClose();
  }
}
