part of 'search_answer_key_controller.dart';

class SearchAnswerKeyController extends GetxController {
  final searchController = TextEditingController();
  final filteredList = <BookletModel>[].obs;
  final isLoading = false.obs;
  final AnswerKeySnapshotRepository _answerKeySnapshotRepository =
      ensureAnswerKeySnapshotRepository();
  int _searchToken = 0;

  @override
  void onInit() {
    super.onInit();
    _handleSearchAnswerKeyOnInit();
  }

  @override
  void onClose() {
    _handleSearchAnswerKeyOnClose();
    super.onClose();
  }

  void resetSearch() => _resetSearchState();

  void navigateToPreview(BookletModel model) {
    Get.to(() => BookletPreview(model: model));
  }
}
