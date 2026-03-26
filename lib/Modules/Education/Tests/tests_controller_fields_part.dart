part of 'tests_controller.dart';

class _TestsControllerState {
  final TestRepository testRepository = TestRepository.ensure();
  final RxList<TestsModel> list = <TestsModel>[].obs;
  final RxBool showButtons = false.obs;
  final RxBool ustBar = true.obs;
  final ScrollController scrollController = ScrollController();
  final RxDouble previousOffset = 0.0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxDouble scrollOffset = 0.0.obs;
  DocumentSnapshot? lastDocument;
}

extension TestsControllerFieldsPart on TestsController {
  TestRepository get _testRepository => _state.testRepository;
  RxList<TestsModel> get list => _state.list;
  RxBool get showButtons => _state.showButtons;
  RxBool get ustBar => _state.ustBar;
  ScrollController get scrollController => _state.scrollController;
  RxDouble get _previousOffset => _state.previousOffset;
  RxBool get isLoading => _state.isLoading;
  RxBool get isLoadingMore => _state.isLoadingMore;
  RxBool get hasMore => _state.hasMore;
  RxDouble get scrollOffset => _state.scrollOffset;
  DocumentSnapshot? get _lastDocument => _state.lastDocument;
  set _lastDocument(DocumentSnapshot? value) => _state.lastDocument = value;
}
