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
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SinavSorusuHazirlaController(
        docID: docID,
        sinavTuru: sinavTuru,
        tumDersler: tumDersler,
        derslerinSoruSayilari: derslerinSoruSayilari,
        complated: complated,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static SinavSorusuHazirlaController? maybeFind({required String tag}) {
    final isRegistered =
        Get.isRegistered<SinavSorusuHazirlaController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SinavSorusuHazirlaController>(tag: tag);
  }

  final _SinavSorusuHazirlaControllerState _state;

  SinavSorusuHazirlaController({
    required String docID,
    required String sinavTuru,
    required List<String> tumDersler,
    required List<String> derslerinSoruSayilari,
    required Function() complated,
  }) : _state = _SinavSorusuHazirlaControllerState(
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
