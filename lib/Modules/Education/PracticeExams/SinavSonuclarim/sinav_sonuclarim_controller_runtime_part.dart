part of 'sinav_sonuclarim_controller_library.dart';

class SinavSonuclarimController extends GetxController {
  final _state = _SinavSonuclarimControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleSinavSonuclarimControllerInit(this);
  }

  @override
  void onClose() {
    _handleSinavSonuclarimControllerClose(this);
    super.onClose();
  }
}

SinavSonuclarimController ensureSinavSonuclarimController({
  bool permanent = false,
}) {
  final existing = maybeFindSinavSonuclarimController();
  if (existing != null) return existing;
  return Get.put(SinavSonuclarimController(), permanent: permanent);
}

SinavSonuclarimController? maybeFindSinavSonuclarimController() {
  final isRegistered = Get.isRegistered<SinavSonuclarimController>();
  if (!isRegistered) return null;
  return Get.find<SinavSonuclarimController>();
}

void _handleSinavSonuclarimControllerInit(
  SinavSonuclarimController controller,
) {
  controller.scrolControlcu();
  unawaited(_SinavSonuclarimControllerRuntimeX(controller).bootstrapData());
}

void _handleSinavSonuclarimControllerClose(
  SinavSonuclarimController controller,
) {
  controller.scrollController.dispose();
}

extension _SinavSonuclarimControllerRuntimeX on SinavSonuclarimController {
  Future<void> bootstrapData() async {
    final currentUserID = CurrentUserService.instance.effectiveUserId;
    if (currentUserID.isEmpty) return;
    final cached = (await _practiceExamSnapshotRepository.loadCachedAnswered(
          userId: currentUserID,
        ))
            .data ??
        const <SinavModel>[];
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
      final exams = forceRefresh
          ? ((await _practiceExamSnapshotRepository.loadAnswered(
                userId: currentUserID,
                forceSync: true,
              ))
                  .data ??
              const <SinavModel>[])
          : ((await _practiceExamSnapshotRepository.loadCachedAnswered(
                userId: currentUserID,
              ))
                  .data ??
              (await _practiceExamSnapshotRepository.loadAnswered(
                userId: currentUserID,
                forceSync: true,
              ))
                  .data ??
              const <SinavModel>[]);
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

extension SinavSonuclarimControllerFacadePart on SinavSonuclarimController {
  void scrolControlcu() =>
      _SinavSonuclarimControllerRuntimeX(this).setupScrollController();

  Future<void> findAndGetSinavlar({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _SinavSonuclarimControllerRuntimeX(this).findAndGetSinavlar(
        silent: silent,
        forceRefresh: forceRefresh,
      );
}
