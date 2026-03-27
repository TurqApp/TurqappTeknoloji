part of 'category_based_answer_key_controller_library.dart';

extension CategoryBasedAnswerKeyControllerRuntimePart
    on CategoryBasedAnswerKeyController {
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

  void _handleCategoryAnswerKeyInit() {
    _bootstrapData();
  }

  void _handleCategoryAnswerKeyClose() {
    search.dispose();
  }

  Future<void> _bootstrapData() async {
    try {
      final cached = await _bookletRepository.fetchByExamType(
        sinavTuru,
        preferCache: true,
        cacheOnly: true,
      );
      if (cached.isNotEmpty) {
        if (!_sameBookletEntries(list, cached)) {
          list.assignAll(cached);
        }
        if (!_sameBookletEntries(filteredList, cached)) {
          filteredList.assignAll(cached);
        }
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'answer_key:type:$sinavTuru',
          minInterval: CategoryBasedAnswerKeyController._silentRefreshInterval,
        )) {
          getData(silent: true, forceRefresh: true);
        }
        return;
      }
    } catch (_) {}

    await getData();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final shouldShowLoader = !silent && list.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final items = await _bookletRepository.fetchByExamType(
        sinavTuru,
        preferCache: true,
        forceRefresh: forceRefresh,
      );
      if (!_sameBookletEntries(list, items)) {
        list.assignAll(items);
      }
      if (!_sameBookletEntries(filteredList, list)) {
        filteredList.assignAll(list);
      }
      SilentRefreshGate.markRefreshed('answer_key:type:$sinavTuru');
    } catch (_) {
    } finally {
      if (shouldShowLoader || list.isEmpty) {
        isLoading.value = false;
      }
    }
  }

  String normalizeText(String text) {
    return normalizeSearchText(text);
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      if (!_sameBookletEntries(filteredList, list)) {
        filteredList.assignAll(list);
      }
    } else {
      final next = list
          .where(
            (val) => normalizeText(val.baslik).contains(normalizeText(query)),
          )
          .toList(growable: false);
      if (!_sameBookletEntries(filteredList, next)) {
        filteredList.assignAll(next);
      }
    }
  }
}

CategoryBasedAnswerKeyController ensureCategoryBasedAnswerKeyController(
  String sinavTuru, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindCategoryBasedAnswerKeyController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CategoryBasedAnswerKeyController(sinavTuru),
    tag: tag,
    permanent: permanent,
  );
}

CategoryBasedAnswerKeyController? maybeFindCategoryBasedAnswerKeyController({
  String? tag,
}) {
  final isRegistered =
      Get.isRegistered<CategoryBasedAnswerKeyController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CategoryBasedAnswerKeyController>(tag: tag);
}
