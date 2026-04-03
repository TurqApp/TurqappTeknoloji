part of 'antreman_score_controller_library.dart';

abstract class _AntremanScoreControllerBase extends GetxController {
  @override
  void onInit() {
    super.onInit();
    final controller = this as AntremanScoreController;
    controller.leaderboard.clear();
    controller.userRank.value = 0;
    controller.isLoading.value = false;
    controller.getUserAntPoint();
  }
}
