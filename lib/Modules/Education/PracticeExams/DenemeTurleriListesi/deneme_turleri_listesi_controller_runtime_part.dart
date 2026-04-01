part of 'deneme_turleri_listesi_controller.dart';

extension DenemeTurleriListesiControllerRuntimePart
    on DenemeTurleriListesiController {
  bool _sameExamEntries(
    List<SinavModel> current,
    List<SinavModel> next,
  ) {
    final currentKeys = current
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

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _getDataImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> _bootstrapDataImpl() async {
    final cached =
        (await _practiceExamSnapshotRepository.loadType(
              userId: CurrentUserService.instance.effectiveUserId,
              examType: sinavTuru,
            ))
                .data ??
            const <SinavModel>[];
    if (cached.isNotEmpty) {
      if (!_sameExamEntries(list, cached)) {
        list.assignAll(cached);
      }
      isLoading.value = false;
      isInitialized.value = true;
      if (SilentRefreshGate.shouldRefresh(
        'practice_exams:type:$sinavTuru',
        minInterval: DenemeTurleriListesiController._silentRefreshInterval,
      )) {
        unawaited(getData(silent: true, forceRefresh: true));
      }
      return;
    }
    await getData();
  }

  Future<void> _getDataImpl({
    required bool silent,
    required bool forceRefresh,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final items =
          (await _practiceExamSnapshotRepository.loadType(
                userId: CurrentUserService.instance.effectiveUserId,
                examType: sinavTuru,
                forceSync: forceRefresh,
              ))
                  .data ??
              const <SinavModel>[];
      if (!_sameExamEntries(list, items)) {
        list.assignAll(items);
      }
      SilentRefreshGate.markRefreshed('practice_exams:type:$sinavTuru');
    } catch (_) {
      AppSnackbar('common.error'.tr, 'tests.exams_load_failed'.tr);
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }
}

DenemeTurleriListesiController ensureDenemeTurleriListesiController({
  required String tag,
  required String sinavTuru,
  bool permanent = false,
}) {
  final existing = maybeFindDenemeTurleriListesiController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    DenemeTurleriListesiController(sinavTuru: sinavTuru),
    tag: tag,
    permanent: permanent,
  );
}

DenemeTurleriListesiController? maybeFindDenemeTurleriListesiController({
  required String tag,
}) {
  final isRegistered =
      Get.isRegistered<DenemeTurleriListesiController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<DenemeTurleriListesiController>(tag: tag);
}
