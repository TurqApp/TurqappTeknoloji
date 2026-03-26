part of 'sinav_sonuclarim_controller_library.dart';

extension _SinavSonuclarimControllerRuntimeX on SinavSonuclarimController {
  Future<void> bootstrapData() async {
    final currentUserID = CurrentUserService.instance.effectiveUserId;
    if (currentUserID.isEmpty) return;
    final cached = await _practiceExamRepository.fetchAnsweredByUser(
      currentUserID,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      if (!_sameExamEntries(cached)) {
        list.assignAll(cached);
      }
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'practice_exams:results:$currentUserID',
        minInterval: _sinavSonuclarimSilentRefreshInterval,
      )) {
        unawaited(findAndGetSinavlar(silent: true, forceRefresh: true));
      }
      return;
    }
    await findAndGetSinavlar(
      silent: false,
      forceRefresh: false,
    );
  }

  Future<void> findAndGetSinavlar({
    required bool silent,
    required bool forceRefresh,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final currentUserID = CurrentUserService.instance.effectiveUserId;
      final exams = await _practiceExamRepository.fetchAnsweredByUser(
        currentUserID,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (!_sameExamEntries(exams)) {
        list.assignAll(exams);
      }
      SilentRefreshGate.markRefreshed('practice_exams:results:$currentUserID');
    } catch (e) {
      log("SinavSonuclarimController error: $e");
      AppSnackbar('common.error'.tr, 'tests.results_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void setupScrollController() {
    scrollController.addListener(() {
      final currentOffset = scrollController.position.pixels;

      if (currentOffset > _previousOffset) {
        if (ustBar.value) ustBar.value = false;
      } else if (currentOffset < _previousOffset) {
        if (!ustBar.value) ustBar.value = true;
      }

      _previousOffset = currentOffset;
    });
  }

  bool _sameExamEntries(List<SinavModel> next) {
    final currentKeys = list
        .map(
          (item) => [
            item.docID,
            item.sinavAdi,
            item.sinavTuru,
            item.timeStamp,
            item.participantCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.sinavAdi,
            item.sinavTuru,
            item.timeStamp,
            item.participantCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }
}
