part of 'biography_maker_controller.dart';

class BiographyMakerController extends GetxController {
  static BiographyMakerController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      BiographyMakerController(),
      permanent: permanent,
    );
  }

  static BiographyMakerController? maybeFind() {
    final isRegistered = Get.isRegistered<BiographyMakerController>();
    if (!isRegistered) return null;
    return Get.find<BiographyMakerController>();
  }

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

  Future<void> setData() => _saveBiographyData(this);
}
