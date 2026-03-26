part of 'search_answer_key_controller.dart';

class SearchAnswerKeyController extends GetxController {
  final _state = _SearchAnswerKeyControllerState();

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
}

class _SearchAnswerKeyControllerState {
  final searchController = TextEditingController();
  final filteredList = <BookletModel>[].obs;
  final isLoading = false.obs;
  final answerKeySnapshotRepository = ensureAnswerKeySnapshotRepository();
  int searchToken = 0;
}

extension SearchAnswerKeyControllerFieldsPart on SearchAnswerKeyController {
  TextEditingController get searchController => _state.searchController;
  RxList<BookletModel> get filteredList => _state.filteredList;
  RxBool get isLoading => _state.isLoading;
  AnswerKeySnapshotRepository get _answerKeySnapshotRepository =>
      _state.answerKeySnapshotRepository;
  int get _searchToken => _state.searchToken;
  set _searchToken(int value) => _state.searchToken = value;
}

SearchAnswerKeyController ensureSearchAnswerKeyController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindSearchAnswerKeyController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SearchAnswerKeyController(),
    tag: tag,
    permanent: permanent,
  );
}

SearchAnswerKeyController? maybeFindSearchAnswerKeyController({String? tag}) {
  final isRegistered = Get.isRegistered<SearchAnswerKeyController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SearchAnswerKeyController>(tag: tag);
}

extension SearchAnswerKeyControllerFacadePart on SearchAnswerKeyController {
  void resetSearch() => _resetSearchState();

  void navigateToPreview(BookletModel model) {
    Get.to(() => BookletPreview(model: model));
  }
}
