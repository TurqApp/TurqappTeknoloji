part of 'sinav_hazirla_controller.dart';

SinavHazirlaController ensureSinavHazirlaController({
  required String tag,
  SinavModel? sinavModel,
  bool permanent = false,
}) =>
    _ensureSinavHazirlaController(
      tag: tag,
      sinavModel: sinavModel,
      permanent: permanent,
    );

SinavHazirlaController? maybeFindSinavHazirlaController({
  required String tag,
}) =>
    _maybeFindSinavHazirlaController(tag: tag);

SinavHazirlaController _ensureSinavHazirlaController({
  required String tag,
  SinavModel? sinavModel,
  bool permanent = false,
}) {
  final existing = _maybeFindSinavHazirlaController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SinavHazirlaController(sinavModel: sinavModel),
    tag: tag,
    permanent: permanent,
  );
}

SinavHazirlaController? _maybeFindSinavHazirlaController({
  required String tag,
}) {
  final isRegistered = Get.isRegistered<SinavHazirlaController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SinavHazirlaController>(tag: tag);
}

String _normalizeSinavHazirlaKpssLisans(String value) {
  if (value == _kpssLisansLegacyOrtaOgretim) {
    return _kpssLisansOrtaogretim;
  }
  return value;
}

void _handleSinavHazirlaInit(SinavHazirlaController controller) {
  controller._initializeFormState();
}

void _handleSinavHazirlaClose(SinavHazirlaController controller) {
  controller._disposeFormControllers();
}

extension SinavHazirlaControllerFacadePart on SinavHazirlaController {
  String _normalizeKpssLisans(String value) =>
      _normalizeSinavHazirlaKpssLisans(value);
}
