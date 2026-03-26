part of 'search_tests_controller.dart';

SearchTestsController _ensureSearchTestsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindSearchTestsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SearchTestsController(),
    tag: tag,
    permanent: permanent,
  );
}

SearchTestsController? _maybeFindSearchTestsController({String? tag}) {
  final isRegistered = Get.isRegistered<SearchTestsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SearchTestsController>(tag: tag);
}

class _SearchTestsControllerState {
  final TestRepository testRepository = TestRepository.ensure();
  final RxList<TestsModel> list = <TestsModel>[].obs;
  final RxList<TestsModel> filteredList = <TestsModel>[].obs;
  final RxBool isLoading = true.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();
}

extension SearchTestsControllerFieldsPart on SearchTestsController {
  TestRepository get _testRepository => _state.testRepository;
  RxList<TestsModel> get list => _state.list;
  RxList<TestsModel> get filteredList => _state.filteredList;
  RxBool get isLoading => _state.isLoading;
  TextEditingController get searchController => _state.searchController;
  FocusNode get focusNode => _state.focusNode;
}
