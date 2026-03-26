part of 'sinav_sorusu_hazirla_controller.dart';

class SinavSorusuHazirlaController extends GetxController {
  static SinavSorusuHazirlaController ensure({
    required String tag,
    required String docID,
    required String sinavTuru,
    required List<String> tumDersler,
    required List<String> derslerinSoruSayilari,
    required Function() complated,
    bool permanent = false,
  }) =>
      _ensureSinavSorusuHazirlaController(
        tag: tag,
        docID: docID,
        sinavTuru: sinavTuru,
        tumDersler: tumDersler,
        derslerinSoruSayilari: derslerinSoruSayilari,
        complated: complated,
        permanent: permanent,
      );

  static SinavSorusuHazirlaController? maybeFind({required String tag}) =>
      _maybeFindSinavSorusuHazirlaController(tag: tag);

  final _SinavSorusuHazirlaControllerState _state;

  SinavSorusuHazirlaController({
    required String docID,
    required String sinavTuru,
    required List<String> tumDersler,
    required List<String> derslerinSoruSayilari,
    required Function() complated,
  }) : _state = _buildSinavSorusuHazirlaControllerState(
          docID: docID,
          sinavTuru: sinavTuru,
          tumDersler: tumDersler,
          derslerinSoruSayilari: derslerinSoruSayilari,
          complated: complated,
        );

  @override
  void onInit() {
    super.onInit();
    _handleInit();
  }
}
