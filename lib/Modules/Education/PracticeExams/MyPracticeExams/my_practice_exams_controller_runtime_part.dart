part of 'my_practice_exams_controller_library.dart';

const Duration _myPracticeExamsSilentRefreshInterval = Duration(minutes: 5);

extension MyPracticeExamsControllerRuntimePart on MyPracticeExamsController {
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

  Future<void> fetchExams({
    bool forceRefresh = false,
    bool silent = false,
  }) =>
      _fetchExamsImpl(
        forceRefresh: forceRefresh,
        silent: silent,
      );

  Future<void> _bootstrapExamsImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      exams.clear();
      isLoading.value = false;
      return;
    }

    try {
      final cached = (await _practiceExamSnapshotRepository.loadOwner(
        userId: uid,
      ))
          .data ??
          const <SinavModel>[];
      if (cached.isNotEmpty) {
        if (!_sameExamEntries(exams, cached)) {
          exams.assignAll(cached);
        }
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'practice_exams:owner:$uid',
          minInterval: _myPracticeExamsSilentRefreshInterval,
        )) {
          unawaited(fetchExams(silent: true, forceRefresh: true));
        }
        return;
      }
    } catch (_) {}

    await fetchExams();
  }

  Future<void> _fetchExamsImpl({
    required bool forceRefresh,
    required bool silent,
  }) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      exams.clear();
      isLoading.value = false;
      return;
    }

    final shouldShowLoader = !silent && exams.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final items = (await _practiceExamSnapshotRepository.loadOwner(
        userId: uid,
        forceSync: forceRefresh,
      ))
          .data ??
          const <SinavModel>[];
      if (!_sameExamEntries(exams, items)) {
        exams.assignAll(items);
      }
      SilentRefreshGate.markRefreshed('practice_exams:owner:$uid');
    } catch (e) {
      log('MyPracticeExamsController.fetchExams error: $e');
      AppSnackbar('common.error'.tr, 'tests.exams_load_failed'.tr);
    } finally {
      if (shouldShowLoader || exams.isEmpty) {
        isLoading.value = false;
      }
    }
  }
}

class MyPracticeExamsController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapExamsImpl());
  }
}

MyPracticeExamsController? maybeFindMyPracticeExamsController() =>
    Get.isRegistered<MyPracticeExamsController>()
        ? Get.find<MyPracticeExamsController>()
        : null;

MyPracticeExamsController ensureMyPracticeExamsController({
  bool permanent = false,
}) =>
    maybeFindMyPracticeExamsController() ??
    Get.put(MyPracticeExamsController(), permanent: permanent);
