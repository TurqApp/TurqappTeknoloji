part of 'optics_and_books_published_controller.dart';

extension _OpticsAndBooksPublishedControllerRuntimeX
    on OpticsAndBooksPublishedController {
  Future<void> _bootstrapData() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      isLoading.value = false;
      return;
    }
    try {
      final cachedBooks = await _bookletRepository.fetchByOwner(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      final cachedOptikler = await _opticalFormRepository.fetchByOwner(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      if (cachedBooks.isNotEmpty || cachedOptikler.isNotEmpty) {
        cachedBooks.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
        cachedOptikler.sort((a, b) => b.docID.compareTo(a.docID));
        if (!_sameBookletEntries(list, cachedBooks)) {
          list.assignAll(cachedBooks);
        }
        if (!_sameOpticalEntries(optikler, cachedOptikler)) {
          optikler.assignAll(cachedOptikler);
        }
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'answer_key:published:$uid',
          minInterval: OpticsAndBooksPublishedController._silentRefreshInterval,
        )) {
          unawaited(loadData(silent: true, forceRefresh: true));
        }
        return;
      }
    } catch (_) {}
    await loadData();
  }

  Future<void> loadData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    final shouldShowLoader = !silent && list.isEmpty && optikler.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    await Future.wait([
      getData(forceRefresh: forceRefresh),
      getOptikler(forceRefresh: forceRefresh),
    ]);
    if (uid.isNotEmpty) {
      SilentRefreshGate.markRefreshed('answer_key:published:$uid');
    }
    if (shouldShowLoader || (list.isEmpty && optikler.isEmpty)) {
      isLoading.value = false;
    }
  }

  Future<void> getData({bool forceRefresh = false}) async {
    final tempList = await _bookletRepository.fetchByOwner(
      CurrentUserService.instance.effectiveUserId,
      preferCache: true,
      forceRefresh: forceRefresh,
    );
    tempList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    if (!_sameBookletEntries(list, tempList)) {
      list.assignAll(tempList);
    }
  }

  Future<void> getOptikler({bool forceRefresh = false}) async {
    final tempList = await _opticalFormRepository.fetchByOwner(
      CurrentUserService.instance.effectiveUserId,
      preferCache: true,
      forceRefresh: forceRefresh,
    );
    tempList.sort((a, b) => b.docID.compareTo(a.docID));
    if (!_sameOpticalEntries(optikler, tempList)) {
      optikler.assignAll(tempList);
    }
  }
}
