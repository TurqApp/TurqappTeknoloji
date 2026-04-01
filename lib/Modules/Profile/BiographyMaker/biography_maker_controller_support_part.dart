part of 'biography_maker_controller.dart';

BiographyMakerController ensureBiographyMakerController({
  bool permanent = false,
}) =>
    _ensureBiographyMakerController(permanent: permanent);

BiographyMakerController? maybeFindBiographyMakerController() =>
    _maybeFindBiographyMakerController();

BiographyMakerController _ensureBiographyMakerController({
  bool permanent = false,
}) {
  final existing = _maybeFindBiographyMakerController();
  if (existing != null) return existing;
  return Get.put(
    BiographyMakerController(),
    permanent: permanent,
  );
}

BiographyMakerController? _maybeFindBiographyMakerController() {
  final isRegistered = Get.isRegistered<BiographyMakerController>();
  if (!isRegistered) return null;
  return Get.find<BiographyMakerController>();
}
