part of 'search_answer_key_controller.dart';

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
