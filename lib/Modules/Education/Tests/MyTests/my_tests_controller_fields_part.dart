part of 'my_tests_controller.dart';

class _MyTestsControllerState {
  final testRepository = ensureTestRepository();
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;
}

extension MyTestsControllerFieldsPart on MyTestsController {
  TestRepository get _testRepository => _state.testRepository;
  RxList<TestsModel> get list => _state.list;
  RxBool get isLoading => _state.isLoading;
}
