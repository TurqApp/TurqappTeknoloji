part of 'search_deneme_controller.dart';

abstract class _SearchDenemeControllerBase extends GetxController {
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
    (this as SearchDenemeController)._handleSearchDenemeOnInit();
  }

  @override
  void onClose() {
    (this as SearchDenemeController)._handleSearchDenemeOnClose();
    super.onClose();
  }
}
