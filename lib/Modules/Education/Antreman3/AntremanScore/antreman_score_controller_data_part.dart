part of 'antreman_score_controller_library.dart';

extension AntremanScoreControllerDataPart on AntremanScoreController {
  Future<void> fetchLeaderboard({bool showLoader = true}) async {
    leaderboard.clear();
    userRank.value = 0;
    isLoading.value = false;
  }
}
