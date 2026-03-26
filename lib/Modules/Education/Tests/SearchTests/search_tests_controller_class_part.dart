part of 'search_tests_controller.dart';

class SearchTestsController extends GetxController {
  static SearchTestsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SearchTestsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static SearchTestsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SearchTestsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SearchTestsController>(tag: tag);
  }

  final TestRepository _testRepository = TestRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <TestsModel>[].obs;
  final filteredList = <TestsModel>[].obs;
  final isLoading = true.obs;
  final searchController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    _handleSearchTestsControllerInit(this);
  }

  void filterSearchResults(String query) =>
      _filterSearchTestsResults(this, query);

  @override
  void onClose() {
    _handleSearchTestsControllerClose(this);
    super.onClose();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _getSearchTestsData(
        this,
        silent: silent,
        forceRefresh: forceRefresh,
      );
}
