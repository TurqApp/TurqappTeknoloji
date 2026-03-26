part of 'sinav_hazirla_controller.dart';

class SinavHazirlaController extends GetxController {
  static SinavHazirlaController ensure({
    required String tag,
    SinavModel? sinavModel,
    bool permanent = false,
  }) =>
      _ensureSinavHazirlaController(
          tag: tag, sinavModel: sinavModel, permanent: permanent);

  static SinavHazirlaController? maybeFind({required String tag}) =>
      _maybeFindSinavHazirlaController(tag: tag);

  final _state = _SinavHazirlaControllerState();
  SinavModel? sinavModel;

  SinavHazirlaController({this.sinavModel});

  String _normalizeKpssLisans(String value) =>
      _normalizeSinavHazirlaKpssLisans(value);

  @override
  void onInit() {
    super.onInit();
    _handleSinavHazirlaInit(this);
  }

  @override
  void onClose() {
    _handleSinavHazirlaClose(this);
    super.onClose();
  }
}
