part of 'deneme_sinavlari_controller.dart';

class DenemeSinavlariController extends GetxController
    with _DenemeSinavlariControllerBasePart {
  static DenemeSinavlariController ensure({
    bool permanent = false,
  }) =>
      _ensureDenemeSinavlariController(permanent: permanent);

  static DenemeSinavlariController? maybeFind() =>
      _maybeFindDenemeSinavlariController();

  @override
  void onInit() {
    super.onInit();
    _handleDenemeSinavlariInit(this);
  }

  @override
  void onClose() {
    _handleDenemeSinavlariClose(this);
    super.onClose();
  }
}
