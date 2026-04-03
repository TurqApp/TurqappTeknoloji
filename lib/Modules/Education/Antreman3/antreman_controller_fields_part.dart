part of 'antreman_controller.dart';

class _AntremanControllerState {
  final expandedIndex = RxInt(-1);
  final selectedSubject = ''.obs;
  final selectedSinavTuru = ''.obs;
  final currentQuestionIndex = 0.obs;
  final selectedAnswers = <String, String>{}.obs;
  final initialAnswers = <String, String>{}.obs;
  final answerStates = <String, bool>{}.obs;
  final likedQuestions = <String, bool>{}.obs;
  final savedQuestions = <String, bool>{}.obs;
  final isSortingEnabled = true.obs;
  final loadingProgress = 0.0.obs;
  final isSubjectSelecting = false.obs;
  final imageAspectRatios = <String, double>{}.obs;
  final justAnswered = ''.obs;
  final searchQuery = ''.obs;
  final searchResults = <QuestionBankModel>[].obs;
  final isSearchLoading = false.obs;
  final expandedSubIndex = RxInt(-1);
  final mainCategory = ''.obs;
  final mainCategoryLoaded = false.obs;
  final questions = <QuestionBankModel>[].obs;
  final savedQuestionsList = <QuestionBankModel>[].obs;
  final categoryPool = <QuestionBankModel>[];
  final loadedQuestionIds = <String>{};
  final answeredQuestionIds = <String>{};
  final activeCategoryKey = ''.obs;
  bool isFetchingMore = false;
  bool mainCategoryPromptShown = false;
  Timer? searchDebounce;
  int searchToken = 0;
}

extension AntremanControllerFieldsPart on AntremanController {
  RxInt get expandedIndex => _state.expandedIndex;
  RxString get selectedSubject => _state.selectedSubject;
  RxString get selectedSinavTuru => _state.selectedSinavTuru;
  RxInt get currentQuestionIndex => _state.currentQuestionIndex;
  RxMap<String, String> get selectedAnswers => _state.selectedAnswers;
  RxMap<String, String> get initialAnswers => _state.initialAnswers;
  RxMap<String, bool> get answerStates => _state.answerStates;
  RxMap<String, bool> get likedQuestions => _state.likedQuestions;
  RxMap<String, bool> get savedQuestions => _state.savedQuestions;
  RxBool get isSortingEnabled => _state.isSortingEnabled;
  RxDouble get loadingProgress => _state.loadingProgress;
  RxBool get isSubjectSelecting => _state.isSubjectSelecting;
  RxMap<String, double> get imageAspectRatios => _state.imageAspectRatios;
  RxString get justAnswered => _state.justAnswered;
  RxString get searchQuery => _state.searchQuery;
  RxList<QuestionBankModel> get searchResults => _state.searchResults;
  RxBool get isSearchLoading => _state.isSearchLoading;
  RxInt get expandedSubIndex => _state.expandedSubIndex;
  RxString get mainCategory => _state.mainCategory;
  RxBool get mainCategoryLoaded => _state.mainCategoryLoaded;
  RxList<QuestionBankModel> get questions => _state.questions;
  RxList<QuestionBankModel> get savedQuestionsList => _state.savedQuestionsList;
  List<QuestionBankModel> get _categoryPool => _state.categoryPool;
  Set<String> get _loadedQuestionIds => _state.loadedQuestionIds;
  Set<String> get _answeredQuestionIds => _state.answeredQuestionIds;
  RxString get _activeCategoryKey => _state.activeCategoryKey;
  bool get _isFetchingMore => _state.isFetchingMore;
  set _isFetchingMore(bool value) => _state.isFetchingMore = value;
  bool get _mainCategoryPromptShown => _state.mainCategoryPromptShown;
  set _mainCategoryPromptShown(bool value) =>
      _state.mainCategoryPromptShown = value;
  Timer? get _searchDebounce => _state.searchDebounce;
  set _searchDebounce(Timer? value) => _state.searchDebounce = value;
  int get _searchToken => _state.searchToken;
  set _searchToken(int value) => _state.searchToken = value;
}
