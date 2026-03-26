part of 'saved_optical_forms_controller_library.dart';

class SavedOpticalFormsControllerRuntimePart {
  const SavedOpticalFormsControllerRuntimePart(this.controller);

  final SavedOpticalFormsController controller;

  bool sameBookletEntries(
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

  Future<void> bootstrapData() async {
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) {
        controller.isLoading.value = false;
        return;
      }
      final savedEntries =
          await controller._userSubcollectionRepository.getEntries(
        uid,
        subcollection: 'books',
        orderByField: 'createdAt',
        descending: true,
        preferCache: true,
        cacheOnly: true,
      );
      if (savedEntries.isNotEmpty) {
        final books = await controller._bookletRepository.fetchByIds(
          savedEntries.map((e) => e.id).toList(growable: false),
          preferCache: true,
          cacheOnly: true,
        );
        if (books.isNotEmpty) {
          if (!controller._sameBookletEntries(controller.list, books)) {
            controller.list.assignAll(books);
          }
          controller.isLoading.value = false;
          if (SilentRefreshGate.shouldRefresh(
            'answer_key:saved_books:$uid',
            minInterval: _savedOpticalFormsSilentRefreshInterval,
          )) {
            unawaited(
              controller.getData(
                silent: true,
                forceRefresh: true,
              ),
            );
          }
          return;
        }
      }
    } catch (_) {}

    await controller.getData();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final shouldShowLoader = !silent && controller.list.isEmpty;
    if (shouldShowLoader) {
      controller.isLoading.value = true;
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      final savedEntries =
          await controller._userSubcollectionRepository.getEntries(
        uid,
        subcollection: 'books',
        orderByField: 'createdAt',
        descending: true,
        preferCache: true,
        forceRefresh: forceRefresh,
      );
      final books = await controller._bookletRepository.fetchByIds(
        savedEntries.map((e) => e.id).toList(growable: false),
        preferCache: true,
      );
      if (!controller._sameBookletEntries(controller.list, books)) {
        controller.list.assignAll(books);
      }
      SilentRefreshGate.markRefreshed('answer_key:saved_books:$uid');
    } catch (_) {
    } finally {
      if (shouldShowLoader || controller.list.isEmpty) {
        controller.isLoading.value = false;
      }
    }
  }
}
