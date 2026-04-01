part of 'my_past_test_results_preview_controller.dart';

class _MyPastTestResultsPreviewControllerState {
  _MyPastTestResultsPreviewControllerState(this.model);

  final TestsModel model;
  final RxList<String> yanitlar = <String>[].obs;
  final RxInt timeStamp = 0.obs;
  final RxList<TestReadinessModel> soruList = <TestReadinessModel>[].obs;
  final RxInt dogruSayisi = 0.obs;
  final RxInt yanlisSayisi = 0.obs;
  final RxInt bosSayisi = 0.obs;
  final RxDouble totalPuan = 0.0.obs;
  final RxBool isLoading = true.obs;
  final TestRepository testRepository = ensureTestRepository();
}

extension MyPastTestResultsPreviewControllerFieldsPart
    on MyPastTestResultsPreviewController {
  TestsModel get model => _state.model;
  RxList<String> get yanitlar => _state.yanitlar;
  RxInt get timeStamp => _state.timeStamp;
  RxList<TestReadinessModel> get soruList => _state.soruList;
  RxInt get dogruSayisi => _state.dogruSayisi;
  RxInt get yanlisSayisi => _state.yanlisSayisi;
  RxInt get bosSayisi => _state.bosSayisi;
  RxDouble get totalPuan => _state.totalPuan;
  RxBool get isLoading => _state.isLoading;
  TestRepository get _testRepository => _state.testRepository;
}
