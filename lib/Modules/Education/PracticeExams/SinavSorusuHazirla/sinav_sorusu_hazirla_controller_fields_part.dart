part of 'sinav_sorusu_hazirla_controller.dart';

class _SinavSorusuHazirlaControllerState {
  _SinavSorusuHazirlaControllerState({
    required this.docID,
    required this.sinavTuru,
    required this.tumDersler,
    required this.derslerinSoruSayilari,
    required this.complated,
  });

  final PracticeExamRepository practiceExamRepository =
      PracticeExamRepository.ensure();
  final RxList<SoruModel> list = <SoruModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;
  final String docID;
  final String sinavTuru;
  final List<String> tumDersler;
  final List<String> derslerinSoruSayilari;
  final Function() complated;
}

extension SinavSorusuHazirlaControllerFieldsPart
    on SinavSorusuHazirlaController {
  PracticeExamRepository get _practiceExamRepository =>
      _state.practiceExamRepository;
  RxList<SoruModel> get list => _state.list;
  RxBool get isLoading => _state.isLoading;
  RxBool get isInitialized => _state.isInitialized;
  String get docID => _state.docID;
  String get sinavTuru => _state.sinavTuru;
  List<String> get tumDersler => _state.tumDersler;
  List<String> get derslerinSoruSayilari => _state.derslerinSoruSayilari;
  Function() get complated => _state.complated;
}
