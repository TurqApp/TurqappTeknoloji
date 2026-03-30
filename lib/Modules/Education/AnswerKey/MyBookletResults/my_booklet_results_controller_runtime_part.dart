part of 'my_booklet_results_controller.dart';

class MyBookletResultsControllerRuntimePart {
  const MyBookletResultsControllerRuntimePart(this.controller);

  final MyBookletResultsController controller;

  Future<void> bootstrapResults() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      controller.isLoading.value = false;
      return;
    }
    try {
      final cachedEntries =
          await controller._userSubcollectionRepository.getEntries(
        uid,
        subcollection: 'KitapcikCevaplari',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: true,
        cacheOnly: true,
      );
      final cachedOptikler =
          (await controller._opticalFormSnapshotRepository.loadCachedAnswered(
                userId: uid,
              ))
                  .data ??
              const <OpticalFormModel>[];
      if (cachedEntries.isNotEmpty || cachedOptikler.isNotEmpty) {
        controller._assignBookletResults(cachedEntries);
        cachedOptikler.sort((a, b) => b.baslangic.compareTo(a.baslangic));
        controller.optikSonuclari.assignAll(cachedOptikler);
        controller.isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'answer_key:results:$uid',
          minInterval: MyBookletResultsController._silentRefreshInterval,
        )) {
          unawaited(
            controller.refreshData(
              silent: true,
              forceRefresh: true,
            ),
          );
        }
        return;
      }
    } catch (_) {}
    await controller.refreshData();
  }

  Future<void> fetchBookletResults({bool forceRefresh = false}) async {
    try {
      final snapshot = await controller._userSubcollectionRepository.getEntries(
        CurrentUserService.instance.effectiveUserId,
        subcollection: 'KitapcikCevaplari',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: true,
        forceRefresh: forceRefresh,
      );
      controller._assignBookletResults(snapshot);
    } catch (_) {}
  }

  Future<void> fetchOptikSonuclari({bool forceRefresh = false}) async {
    final currentUserUID = CurrentUserService.instance.effectiveUserId;

    try {
      final tempList = forceRefresh
          ? ((await controller._opticalFormSnapshotRepository.loadAnswered(
                userId: currentUserUID,
                forceSync: true,
              ))
                  .data ??
              const <OpticalFormModel>[])
          : ((await controller._opticalFormSnapshotRepository
                      .loadCachedAnswered(
                userId: currentUserUID,
              ))
                  .data ??
              (await controller._opticalFormSnapshotRepository.loadAnswered(
                userId: currentUserUID,
                forceSync: true,
              ))
                  .data ??
              const <OpticalFormModel>[]);

      tempList.sort((a, b) => b.baslangic.compareTo(a.baslangic));
      controller.optikSonuclari.assignAll(tempList);
    } catch (_) {}
  }

  Future<void> refreshData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    final shouldShowLoader =
        !silent && controller.list.isEmpty && controller.optikSonuclari.isEmpty;
    if (shouldShowLoader) {
      controller.isLoading.value = true;
    }
    await Future.wait([
      controller.fetchBookletResults(forceRefresh: forceRefresh),
      controller.fetchOptikSonuclari(forceRefresh: forceRefresh),
    ]);
    if (uid.isNotEmpty) {
      SilentRefreshGate.markRefreshed('answer_key:results:$uid');
    }
    if (shouldShowLoader ||
        (controller.list.isEmpty && controller.optikSonuclari.isEmpty)) {
      controller.isLoading.value = false;
    }
  }

  void assignBookletResults(List<UserSubcollectionEntry> snapshot) {
    final tempList = <BookletResultModel>[];
    for (final doc in snapshot) {
      final data = doc.data;
      tempList.add(
        BookletResultModel(
          cevaplar: List.from(data['cevaplar'] ?? []),
          docID: doc.id,
          baslik: data['baslik'] ?? '',
          timeStamp: data['timeStamp'] ?? 0,
          yanlis: data['yanlis'] ?? 0,
          dogru: data['dogru'] ?? 0,
          bos: data['bos'] ?? 0,
          kitapcikID: data['kitapcikID'] ?? '',
          puan: data['puan'] ?? 0,
          dogruCevaplar: List.from(data['dogruCevaplar'] ?? []),
        ),
      );
    }
    controller.list.assignAll(tempList);
  }
}
