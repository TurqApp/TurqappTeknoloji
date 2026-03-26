part of 'saved_tests_controller.dart';

class _SavedTestsControllerState {
  final testRepository = ensureTestRepository();
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;
}

extension SavedTestsControllerFieldsPart on SavedTestsController {
  TestRepository get _testRepository => _state.testRepository;
  RxList<TestsModel> get list => _state.list;
  RxBool get isLoading => _state.isLoading;
}
