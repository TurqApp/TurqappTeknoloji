part of 'sinav_sonuclari_preview_controller.dart';

class _SinavSonuclariPreviewControllerState {
  _SinavSonuclariPreviewControllerState({required this.model});

  final RxList<String> yanitlar = <String>[].obs;
  final Rx<num> timeStamp = (0 as num).obs;
  final RxList<SoruModel> soruList = <SoruModel>[].obs;
  final RxMap<String, bool> expandedCategories = <String, bool>{}.obs;
  final RxList<DersVeSonuclarDB> dersVeSonuclar = <DersVeSonuclarDB>[].obs;
  final RxString yanitID = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;
  final SinavModel model;
  final PracticeExamRepository practiceExamRepository =
      PracticeExamRepository.ensure();
}

extension SinavSonuclariPreviewControllerFieldsPart
    on SinavSonuclariPreviewController {
  RxList<String> get yanitlar => _state.yanitlar;
  Rx<num> get timeStamp => _state.timeStamp;
  RxList<SoruModel> get soruList => _state.soruList;
  RxMap<String, bool> get expandedCategories => _state.expandedCategories;
  RxList<DersVeSonuclarDB> get dersVeSonuclar => _state.dersVeSonuclar;
  RxString get yanitID => _state.yanitID;
  RxBool get isLoading => _state.isLoading;
  RxBool get isInitialized => _state.isInitialized;
  SinavModel get model => _state.model;
  PracticeExamRepository get _practiceExamRepository =>
      _state.practiceExamRepository;
}
