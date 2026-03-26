part of 'sinav_sonuclari_preview_controller.dart';

class SinavSonuclariPreviewController extends GetxController {
  final _SinavSonuclariPreviewControllerState _state;

  SinavSonuclariPreviewController({required SinavModel model})
      : _state = _SinavSonuclariPreviewControllerState(model: model);

  @override
  void onInit() {
    super.onInit();
    _handleInit();
  }

  Future<void> getYanitlar() => _loadAnswers();

  Future<void> getSorular() => _loadQuestions();

  Future<void> getDersVeSonuclar(String docID) => _loadLessonResults(docID);

  void toggleCategory(String ders) => _toggleCategory(ders);
}
