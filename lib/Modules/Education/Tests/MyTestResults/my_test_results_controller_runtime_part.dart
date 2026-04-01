part of 'my_test_results_controller.dart';

class MyTestResultsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _MyTestResultsControllerState();

  @override
  void onInit() {
    super.onInit();
    handleRuntimeInit();
  }
}

class _MyTestResultsControllerState {
  final testSnapshotRepository = ensureTestSnapshotRepository();
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;
}

extension MyTestResultsControllerFieldsPart on MyTestResultsController {
  TestSnapshotRepository get _testSnapshotRepository =>
      _state.testSnapshotRepository;
  RxList<TestsModel> get list => _state.list;
  RxBool get isLoading => _state.isLoading;
}

extension MyTestResultsControllerRuntimePart on MyTestResultsController {
  void handleRuntimeInit() {
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final currentUserID = CurrentUserService.instance.effectiveUserId;
    final cached = (await _testSnapshotRepository.loadCachedAnswered(
          userId: currentUserID,
        ))
            .data ??
        const <TestsModel>[];
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:answered:$currentUserID',
        minInterval: MyTestResultsController._silentRefreshInterval,
      )) {
        unawaited(findAndGetTestler(silent: true, forceRefresh: true));
      }
      return;
    }
    await findAndGetTestler();
  }

  Future<void> findAndGetTestler({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final currentUserID = CurrentUserService.instance.effectiveUserId;
      final items = forceRefresh
          ? ((await _testSnapshotRepository.loadAnswered(
                userId: currentUserID,
                forceSync: true,
              ))
                  .data ??
              const <TestsModel>[])
          : ((await _testSnapshotRepository.loadCachedAnswered(
                userId: currentUserID,
              ))
                  .data ??
              (await _testSnapshotRepository.loadAnswered(
                userId: currentUserID,
                forceSync: true,
              ))
                  .data ??
              const <TestsModel>[]);
      list.assignAll(items);
      SilentRefreshGate.markRefreshed('tests:answered:$currentUserID');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
