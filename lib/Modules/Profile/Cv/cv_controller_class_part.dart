part of 'cv_controller.dart';

class CvController extends GetxController {
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

const Duration _cvSilentRefreshInterval = Duration(minutes: 5);
const List<String> cvLanguageOptionKeys = <String>[
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
