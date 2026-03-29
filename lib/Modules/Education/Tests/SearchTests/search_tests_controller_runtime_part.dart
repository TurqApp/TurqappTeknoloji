part of 'search_tests_controller.dart';

class SearchTestsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _SearchTestsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleSearchTestsControllerInit(this);
  }

  @override
  void onClose() {
    _handleSearchTestsControllerClose(this);
    super.onClose();
  }
}

class _SearchTestsControllerState {
  final TestSnapshotRepository testSnapshotRepository =
      ensureTestSnapshotRepository();
  final RxList<TestsModel> list = <TestsModel>[].obs;
  final RxList<TestsModel> filteredList = <TestsModel>[].obs;
  final RxBool isLoading = true.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();
}

extension SearchTestsControllerFieldsPart on SearchTestsController {
  TestSnapshotRepository get _testSnapshotRepository =>
      _state.testSnapshotRepository;
  RxList<TestsModel> get list => _state.list;
  RxList<TestsModel> get filteredList => _state.filteredList;
  RxBool get isLoading => _state.isLoading;
  TextEditingController get searchController => _state.searchController;
  FocusNode get focusNode => _state.focusNode;
}

void _handleSearchTestsControllerInit(SearchTestsController controller) {
  unawaited(_bootstrapSearchTestsData(controller));
  Future.delayed(const Duration(milliseconds: 100), () {
    Get.focusScope?.requestFocus(controller.focusNode);
  });
}

void _handleSearchTestsControllerClose(SearchTestsController controller) {
  controller.searchController.dispose();
  controller.focusNode.dispose();
}

void _filterSearchTestsResults(
  SearchTestsController controller,
  String query,
) {
  final normalizedQuery = normalizeSearchText(query);
  if (normalizedQuery.isEmpty) {
    controller.filteredList.assignAll(controller.list);
    return;
  }
  controller.filteredList.assignAll(
    controller.list.where(
      (test) =>
          normalizeSearchText(test.aciklama).contains(normalizedQuery) ||
          normalizeSearchText(test.testTuru).contains(normalizedQuery) ||
          test.dersler.any(
            (ders) => normalizeSearchText(ders).contains(normalizedQuery),
          ),
    ),
  );
}

Future<void> _bootstrapSearchTestsData(SearchTestsController controller) async {
  final uid = CurrentUserService.instance.effectiveUserId;
  final cached = (await controller._testSnapshotRepository.loadCachedAll(
        userId: uid,
      ))
          .data ??
      const <TestsModel>[];
  if (cached.isNotEmpty) {
    controller.list.assignAll(cached);
    controller.filteredList.assignAll(cached);
    controller.isLoading.value = false;
    if (SilentRefreshGate.shouldRefresh(
      'tests:search_all',
      minInterval: SearchTestsController._silentRefreshInterval,
    )) {
      unawaited(
        controller.getData(
          silent: true,
          forceRefresh: true,
        ),
      );
    }
    return;
  }
  await controller.getData();
}

Future<void> _getSearchTestsData(
  SearchTestsController controller, {
  required bool silent,
  required bool forceRefresh,
}) async {
  if (!silent || controller.list.isEmpty) {
    controller.isLoading.value = true;
  }
  final uid = CurrentUserService.instance.effectiveUserId;
  final items = forceRefresh
      ? ((await controller._testSnapshotRepository.loadAll(
            userId: uid,
            forceSync: true,
          ))
              .data ??
          const <TestsModel>[])
      : ((await controller._testSnapshotRepository.loadCachedAll(
            userId: uid,
          ))
              .data ??
          (await controller._testSnapshotRepository.loadAll(
            userId: uid,
            forceSync: true,
          ))
              .data ??
          const <TestsModel>[]);
  controller.list.assignAll(items);
  _filterSearchTestsResults(controller, controller.searchController.text);
  SilentRefreshGate.markRefreshed('tests:search_all');
  controller.isLoading.value = false;
}
