part of 'search_answer_key_controller.dart';

extension SearchAnswerKeyControllerRuntimePart on SearchAnswerKeyController {
  void _resetSearchState() {
    _searchToken++;
    searchController.clear();
    if (filteredList.isNotEmpty) {
      filteredList.clear();
    }
    isLoading.value = false;
  }

  void _handleSearchAnswerKeyOnInit() {
    searchController.addListener(() {
      onSearchChanged(searchController.text);
    });
  }

  void _handleSearchAnswerKeyOnClose() {
    searchController.dispose();
  }

  Future<void> onSearchChanged(String value) async {
    final normalized = value.trim();
    final token = ++_searchToken;
    if (normalized.length < 2) {
      if (filteredList.isNotEmpty) {
        filteredList.clear();
      }
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final resource = await _answerKeySnapshotRepository.search(
        query: normalized,
        userId: CurrentUserService.instance.effectiveUserId,
        limit: 40,
        forceSync: true,
      );
      if (token != _searchToken) return;
      final results = resource.data ?? const <BookletModel>[];
      if (!_sameBookletEntries(filteredList, results)) {
        filteredList.assignAll(results);
      }
    } catch (e) {
      log('Answer key typesense search error: $e');
      if (token == _searchToken && filteredList.isNotEmpty) {
        filteredList.clear();
      }
    } finally {
      if (token == _searchToken) {
        isLoading.value = false;
      }
    }
  }

  bool _sameBookletEntries(
    List<BookletModel> current,
    List<BookletModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.sinavTuru,
            item.yayinEvi,
            item.basimTarihi,
            item.dil,
            item.timeStamp,
            item.viewCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.sinavTuru,
            item.yayinEvi,
            item.basimTarihi,
            item.dil,
            item.timeStamp,
            item.viewCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }
}

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
