part of 'test_entry_controller.dart';

class TestEntryController extends GetxController {
  final _state = _TestEntryControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleTestEntryOnInit();
  }

  @override
  void onClose() {
    _handleTestEntryOnClose();
    super.onClose();
  }
}

class _TestEntryControllerState {
  final textController = TextEditingController();
  final focusNode = FocusNode();
  final model = Rx<TestsModel?>(null);
  final isLoading = false.obs;
  final testRepository = ensureTestRepository();
  final helper = CreateTestController(null);
}

extension TestEntryControllerFieldsPart on TestEntryController {
  TextEditingController get textController => _state.textController;
  FocusNode get focusNode => _state.focusNode;
  Rx<TestsModel?> get model => _state.model;
  RxBool get isLoading => _state.isLoading;
  TestRepository get _testRepository => _state.testRepository;
  CreateTestController get _helper => _state.helper;
}

extension TestEntryControllerRuntimePart on TestEntryController {
  void _handleTestEntryOnInit() {
    focusNode.requestFocus();
  }

  void _handleTestEntryOnClose() {
    textController.dispose();
    focusNode.dispose();
  }

  void joinTest(BuildContext context) {
    if (model.value == null) return;
    const EducationTestNavigationService()
        .openSolveTest(testID: model.value!.docID, showSucces: showAlert)
        .then((_) {
      model.value = null;
      textController.text = '';
    });
  }

  void showAlert() {
    showAlertDialog(
      Get.context!,
      'tests.completed_title'.tr,
      'tests.completed_body'.tr,
    );
  }
}
