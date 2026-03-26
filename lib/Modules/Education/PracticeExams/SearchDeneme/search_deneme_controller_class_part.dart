part of 'search_deneme_controller.dart';

class SearchDenemeController extends GetxController {
  static SearchDenemeController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SearchDenemeController(), permanent: permanent);
  }

  static SearchDenemeController? maybeFind() {
    final isRegistered = Get.isRegistered<SearchDenemeController>();
    if (!isRegistered) return null;
    return Get.find<SearchDenemeController>();
  }

  final PracticeExamSnapshotRepository _practiceExamSnapshotRepository =
      PracticeExamSnapshotRepository.ensure();
  final filteredList = <SinavModel>[].obs;
  final isLoading = false.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  int _searchToken = 0;

  @override
  void onInit() {
    super.onInit();
    _handleSearchDenemeOnInit();
  }

  Future<void> getData() => _performSearchDenemeDataLoad();

  Future<void> filterSearchResults(String query) =>
      _performFilterSearchResults(query);

  void resetSearch() => _resetSearchState();

  @override
  void onClose() {
    _handleSearchDenemeOnClose();
    super.onClose();
  }
}
