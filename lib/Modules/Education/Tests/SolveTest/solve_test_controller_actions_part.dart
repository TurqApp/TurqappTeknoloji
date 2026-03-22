part of 'solve_test_controller.dart';

extension SolveTestControllerActionsPart on SolveTestController {
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void updateAnswer(int index, String choice) {
    cevaplar[index] = choice;
  }

  void testiBitir() {
    _testRepository
        .submitAnswers(
          testID,
          userId: CurrentUserService.instance.effectiveUserId,
          answers: cevaplar.toList(growable: false),
        )
        .catchError((error) {});
    Get.back();
    showSucces();
  }
}
