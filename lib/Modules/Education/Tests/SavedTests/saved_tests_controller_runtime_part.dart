part of 'saved_tests_controller.dart';

class SavedTestsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _SavedTestsControllerState();

  @override
  void onInit() {
    super.onInit();
    handleRuntimeInit();
  }
}

class _SavedTestsControllerState {
  final testSnapshotRepository = ensureTestSnapshotRepository();
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;
}

extension SavedTestsControllerFieldsPart on SavedTestsController {
  TestSnapshotRepository get _testSnapshotRepository =>
      _state.testSnapshotRepository;
  RxList<TestsModel> get list => _state.list;
  RxBool get isLoading => _state.isLoading;
}

extension SavedTestsControllerRuntimePart on SavedTestsController {
  void handleRuntimeInit() {
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    final cached = (await _testSnapshotRepository.loadCachedFavorites(
          userId: uid,
        ))
            .data ??
        const <TestsModel>[];
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:saved:$uid',
        minInterval: SavedTestsController._silentRefreshInterval,
      )) {
        unawaited(getData(silent: true, forceRefresh: true));
      }
      return;
    }
    await getData();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      final items = forceRefresh
          ? ((await _testSnapshotRepository.loadFavorites(
                userId: uid,
                forceSync: true,
              ))
                  .data ??
              const <TestsModel>[])
          : ((await _testSnapshotRepository.loadCachedFavorites(
                userId: uid,
              ))
                  .data ??
              (await _testSnapshotRepository.loadFavorites(
                userId: uid,
                forceSync: true,
              ))
                  .data ??
              const <TestsModel>[]);
      list.assignAll(items);
      SilentRefreshGate.markRefreshed('tests:saved:$uid');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
