part of 'category_based_answer_key_controller_library.dart';

class _CategoryBasedAnswerKeyControllerState {
  _CategoryBasedAnswerKeyControllerState({required this.sinavTuru});

  final String sinavTuru;
  final RxList<BookletModel> list = <BookletModel>[].obs;
  final RxList<BookletModel> filteredList = <BookletModel>[].obs;
  final TextEditingController search = TextEditingController();
  final RxBool isLoading = true.obs;
  final AnswerKeySnapshotRepository answerKeySnapshotRepository =
      ensureAnswerKeySnapshotRepository();
  final BookletRepository bookletRepository = ensureBookletRepository();
}

extension CategoryBasedAnswerKeyControllerFieldsPart
    on CategoryBasedAnswerKeyController {
  String get sinavTuru => _state.sinavTuru;
  RxList<BookletModel> get list => _state.list;
  RxList<BookletModel> get filteredList => _state.filteredList;
  TextEditingController get search => _state.search;
  RxBool get isLoading => _state.isLoading;
  AnswerKeySnapshotRepository get _answerKeySnapshotRepository =>
      _state.answerKeySnapshotRepository;
  BookletRepository get _bookletRepository => _state.bookletRepository;
}
