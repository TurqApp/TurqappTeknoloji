part of 'antreman_controller.dart';

class AntremanController extends GetxController
    with _AntremanControllerBasePart {
  @override
  void onInit() {
    super.onInit();
    _antremanInit(this);
  }

  @override
  void onClose() {
    _antremanClose(this);
    super.onClose();
  }
}
