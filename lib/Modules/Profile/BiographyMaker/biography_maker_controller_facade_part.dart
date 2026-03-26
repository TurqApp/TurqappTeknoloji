part of 'biography_maker_controller.dart';

BiographyMakerController ensureBiographyMakerController({
  bool permanent = false,
}) =>
    _ensureBiographyMakerController(permanent: permanent);

BiographyMakerController? maybeFindBiographyMakerController() =>
    _maybeFindBiographyMakerController();

extension BiographyMakerControllerFacadePart on BiographyMakerController {
  Future<void> setData() => _saveBiographyData(this);
}
