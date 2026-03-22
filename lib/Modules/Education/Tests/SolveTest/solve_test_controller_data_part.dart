part of 'solve_test_controller.dart';

extension SolveTestControllerDataPart on SolveTestController {
  void _handleControllerInit() {
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedTime.value = DateTime.now().difference(_startTime);
    });
    unawaited(getSorular());
    unawaited(getUserFullName());
  }

  void _handleControllerClose() {
    _timer.cancel();
  }

  Future<void> getSorular() async {
    isLoading.value = true;
    try {
      soruList.assignAll(
        await _testRepository.fetchQuestions(
          testID,
          preferCache: true,
        ),
      );
      cevaplar.assignAll(List.generate(soruList.length, (index) => ''));
    } catch (_) {
      soruList.clear();
      cevaplar.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getUserFullName() async {
    try {
      final summary = await _userSummaryResolver.resolve(
        CurrentUserService.instance.effectiveUserId,
        preferCache: true,
      );
      fullname.value = summary?.preferredName ?? '';
    } catch (_) {
      fullname.value = '';
    }
  }
}
