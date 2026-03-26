part of 'sinav_sorusu_hazirla_controller.dart';

SinavSorusuHazirlaController _ensureSinavSorusuHazirlaController({
  required String tag,
  required String docID,
  required String sinavTuru,
  required List<String> tumDersler,
  required List<String> derslerinSoruSayilari,
  required Function() complated,
  bool permanent = false,
}) {
  final existing = _maybeFindSinavSorusuHazirlaController(tag: tag);
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

SinavSorusuHazirlaController? _maybeFindSinavSorusuHazirlaController({
  required String tag,
}) {
  final isRegistered = Get.isRegistered<SinavSorusuHazirlaController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SinavSorusuHazirlaController>(tag: tag);
}

_SinavSorusuHazirlaControllerState _buildSinavSorusuHazirlaControllerState({
  required String docID,
  required String sinavTuru,
  required List<String> tumDersler,
  required List<String> derslerinSoruSayilari,
  required Function() complated,
}) {
  return _SinavSorusuHazirlaControllerState(
    docID: docID,
    sinavTuru: sinavTuru,
    tumDersler: tumDersler,
    derslerinSoruSayilari: derslerinSoruSayilari,
    complated: complated,
  );
}
