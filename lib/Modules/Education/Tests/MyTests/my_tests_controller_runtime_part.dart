part of 'my_tests_controller.dart';

class MyTestsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _MyTestsControllerState();

  @override
  void onInit() {
    super.onInit();
    handleRuntimeInit();
  }
}

class _MyTestsControllerState {
  final testRepository = ensureTestRepository();
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;
}

extension MyTestsControllerFieldsPart on MyTestsController {
  TestRepository get _testRepository => _state.testRepository;
  RxList<TestsModel> get list => _state.list;
  RxBool get isLoading => _state.isLoading;
}

extension MyTestsControllerRuntimePart on MyTestsController {
  void handleRuntimeInit() {
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    final cached = await _testRepository.fetchByOwner(
      uid,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:owner:$uid',
        minInterval: MyTestsController._silentRefreshInterval,
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
      final items = await _testRepository.fetchByOwner(
        uid,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      list.assignAll(items);
      SilentRefreshGate.markRefreshed('tests:owner:$uid');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
