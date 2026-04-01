part of 'optics_and_books_published_controller_library.dart';

extension _OpticsAndBooksPublishedControllerRuntimeX
    on OpticsAndBooksPublishedController {
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

  bool _sameOpticalEntries(
    List<OpticalFormModel> current,
    List<OpticalFormModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.name,
            item.userID,
            item.cevaplar.length,
            item.max,
            item.baslangic,
            item.bitis,
            item.kisitlama,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.name,
            item.userID,
            item.cevaplar.length,
            item.max,
            item.baslangic,
            item.bitis,
            item.kisitlama,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  Future<void> _bootstrapData() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      isLoading.value = false;
      return;
    }
    try {
      final cachedBooks = (await _answerKeySnapshotRepository.loadCachedOwner(
            userId: uid,
          ))
              .data ??
          const <BookletModel>[];
      final cachedOptikler =
          (await _opticalFormSnapshotRepository.loadCachedOwner(
                userId: uid,
              ))
                  .data ??
              const <OpticalFormModel>[];
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
    final tempList = (await _answerKeySnapshotRepository.loadOwner(
          userId: CurrentUserService.instance.effectiveUserId,
          forceSync: forceRefresh,
        ))
            .data ??
        <BookletModel>[];
    tempList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    if (!_sameBookletEntries(list, tempList)) {
      list.assignAll(tempList);
    }
  }

  Future<void> getOptikler({bool forceRefresh = false}) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    final tempList = forceRefresh
        ? ((await _opticalFormSnapshotRepository.loadOwner(
              userId: uid,
              forceSync: true,
            ))
                .data ??
            const <OpticalFormModel>[])
        : ((await _opticalFormSnapshotRepository.loadCachedOwner(
              userId: uid,
            ))
                .data ??
            (await _opticalFormSnapshotRepository.loadOwner(
              userId: uid,
              forceSync: true,
            ))
                .data ??
            const <OpticalFormModel>[]);
    tempList.sort((a, b) => b.docID.compareTo(a.docID));
    if (!_sameOpticalEntries(optikler, tempList)) {
      optikler.assignAll(tempList);
    }
  }
}
