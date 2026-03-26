part of 'sinav_sonuclari_preview_controller.dart';

SinavSonuclariPreviewController ensureSinavSonuclariPreviewController({
  required String tag,
  required SinavModel model,
  bool permanent = false,
}) =>
    _ensureSinavSonuclariPreviewController(
      tag: tag,
      model: model,
      permanent: permanent,
    );

SinavSonuclariPreviewController? maybeFindSinavSonuclariPreviewController({
  required String tag,
}) =>
    _maybeFindSinavSonuclariPreviewController(tag: tag);
