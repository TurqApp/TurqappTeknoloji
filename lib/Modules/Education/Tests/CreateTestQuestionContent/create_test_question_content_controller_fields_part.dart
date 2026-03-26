part of 'create_test_question_content_controller_library.dart';

class _CreateTestQuestionContentControllerState {
  _CreateTestQuestionContentControllerState(
      this.model, this.testID, this.index);

  final TestReadinessModel model;
  final String testID;
  final int index;
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxString focunImage = ''.obs;
  final RxInt selection = 5.obs;
  final RxString dogruCevap = ''.obs;
  final RxList<String> selections = ['A'].obs;
  final RxBool isLoading = false.obs;
  final RxBool isInvalid = false.obs;
}

extension CreateTestQuestionContentControllerFieldsPart
    on CreateTestQuestionContentController {
  TestReadinessModel get model => _state.model;
  String get testID => _state.testID;
  int get index => _state.index;
  Rx<File?> get selectedImage => _state.selectedImage;
  RxString get focunImage => _state.focunImage;
  RxInt get selection => _state.selection;
  RxString get dogruCevap => _state.dogruCevap;
  RxList<String> get selections => _state.selections;
  RxBool get isLoading => _state.isLoading;
  RxBool get isInvalid => _state.isInvalid;
}
