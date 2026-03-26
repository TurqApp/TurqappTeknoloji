part of 'biography_maker_controller.dart';

class BiographyMakerController extends GetxController {
  static BiographyMakerController ensure({bool permanent = false}) =>
      _ensureBiographyMakerController(permanent: permanent);

  static BiographyMakerController? maybeFind() =>
      _maybeFindBiographyMakerController();

  final _state = _BiographyMakerControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleBiographyMakerInit(this);
  }

  @override
  void onClose() {
    _handleBiographyMakerClose(this);
    super.onClose();
  }
}
