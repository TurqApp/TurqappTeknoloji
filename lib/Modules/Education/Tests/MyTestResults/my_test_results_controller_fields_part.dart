part of 'my_test_results_controller.dart';

class _MyTestResultsControllerState {
  final testRepository = ensureTestRepository();
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;
}

extension MyTestResultsControllerFieldsPart on MyTestResultsController {
  TestRepository get _testRepository => _state.testRepository;
  RxList<TestsModel> get list => _state.list;
  RxBool get isLoading => _state.isLoading;
}
