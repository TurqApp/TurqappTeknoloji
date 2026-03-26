part of 'cv_controller.dart';

class CvController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  static const List<String> languageOptionKeys = <String>[
    'cv.language.english',
    'cv.language.german',
    'cv.language.french',
    'cv.language.spanish',
    'cv.language.arabic',
    'cv.language.turkish',
    'cv.language.russian',
    'cv.language.italian',
    'cv.language.korean',
  ];
  final _state = _CvControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleCvControllerInit(this);
  }

  @override
  void onClose() {
    _handleCvControllerClose(this);
    super.onClose();
  }
}
