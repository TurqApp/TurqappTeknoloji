part of 'antreman_score_controller_library.dart';

abstract class _AntremanScoreControllerBase extends GetxController {
  @override
  void onInit() {
    super.onInit();
    final controller = this as AntremanScoreController;
    final hasWarmCache = controller._applyWarmCache();
    if (hasWarmCache) {
      unawaited(controller.fetchLeaderboard(showLoader: false));
    } else {
      controller.fetchLeaderboard();
    }
    controller.getUserAntPoint();
  }
}
