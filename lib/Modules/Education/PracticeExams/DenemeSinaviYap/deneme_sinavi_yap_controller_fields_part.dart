part of 'deneme_sinavi_yap_controller.dart';

class _DenemeSinaviYapControllerState {
  final fullName = ''.obs;
  final list = <SoruModel>[].obs;
  final selectedAnswers = <String>[].obs;
  final dersSonuclari = <DersVeSonuclar>[].obs;
  final selection = 0.obs;
  final isConnected = true.obs;
  final hataCount = 0.obs;
  final isLoading = true.obs;
  final isInitialized = false.obs;
}

extension DenemeSinaviYapControllerFieldsPart on DenemeSinaviYapController {
  RxString get fullName => _state.fullName;
  RxList<SoruModel> get list => _state.list;
  RxList<String> get selectedAnswers => _state.selectedAnswers;
  RxList<DersVeSonuclar> get dersSonuclari => _state.dersSonuclari;
  RxInt get selection => _state.selection;
  RxBool get isConnected => _state.isConnected;
  RxInt get hataCount => _state.hataCount;
  RxBool get isLoading => _state.isLoading;
  RxBool get isInitialized => _state.isInitialized;
}
