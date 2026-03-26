part of 'add_test_question_controller.dart';

class _AddTestQuestionControllerState {
  _AddTestQuestionControllerState({
    required this.initialSoruList,
    required this.testID,
    required this.testTuru,
    required this.onUpdate,
  });

  final List<TestReadinessModel> initialSoruList;
  final String testID;
  final String testTuru;
  final Function onUpdate;
  final soruList = <TestReadinessModel>[].obs;
  final selectedImage = Rx<File?>(null);
  final dogruCevap = ''.obs;
  final selection = 5.obs;
  final selections = ['A'].obs;
  final isLoading = true.obs;
  final picker = ImagePicker();
  final testRepository = TestRepository.ensure();
}

extension AddTestQuestionControllerFieldsPart on AddTestQuestionController {
  List<TestReadinessModel> get initialSoruList => _state.initialSoruList;
  String get testID => _state.testID;
  String get testTuru => _state.testTuru;
  Function get onUpdate => _state.onUpdate;
  RxList<TestReadinessModel> get soruList => _state.soruList;
  Rx<File?> get selectedImage => _state.selectedImage;
  RxString get dogruCevap => _state.dogruCevap;
  RxInt get selection => _state.selection;
  RxList<String> get selections => _state.selections;
  RxBool get isLoading => _state.isLoading;
  ImagePicker get picker => _state.picker;
  TestRepository get _testRepository => _state.testRepository;
}
