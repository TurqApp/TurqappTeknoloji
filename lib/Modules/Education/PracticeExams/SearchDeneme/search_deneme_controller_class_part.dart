part of 'search_deneme_controller.dart';

class SearchDenemeController extends GetxController {
  final PracticeExamSnapshotRepository _practiceExamSnapshotRepository =
      ensurePracticeExamSnapshotRepository();
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

  @override
  void onClose() {
    _handleSearchDenemeOnClose();
    super.onClose();
  }
}
