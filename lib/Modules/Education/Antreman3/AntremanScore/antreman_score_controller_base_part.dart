part of 'antreman_score_controller_library.dart';

abstract class _AntremanScoreControllerBase extends GetxController {
  @override
  void onInit() {
    super.onInit();
    final controller = this as AntremanScoreController;
    if (controller._applyWarmCache()) {
      unawaited(controller.fetchLeaderboard(showLoader: false));
    } else
      controller.fetchLeaderboard();
    controller.getUserAntPoint();
  }
}
