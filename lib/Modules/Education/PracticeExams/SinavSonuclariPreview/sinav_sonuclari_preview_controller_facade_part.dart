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

extension SinavSonuclariPreviewControllerFacadePart
    on SinavSonuclariPreviewController {
  Future<void> getYanitlar() => _loadAnswers();

  Future<void> getSorular() => _loadQuestions();

  Future<void> getDersVeSonuclar(String docID) => _loadLessonResults(docID);

  void toggleCategory(String ders) => _toggleCategory(ders);
}
