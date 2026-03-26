part of 'test_entry_controller.dart';

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
