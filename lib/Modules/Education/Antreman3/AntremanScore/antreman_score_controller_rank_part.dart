part of 'antreman_score_controller_library.dart';

extension AntremanScoreControllerRankPart on AntremanScoreController {
  Future<void> getUserAntPoint() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    final monthlyScore = await _antremanRepository.getMonthlyScore(uid);
    if (monthlyScore != null) {
      userPoint.value = monthlyScore;
    } else {
      final userData = await _userRepository.getUserRaw(
        uid,
        preferCache: true,
      );
      userPoint.value = ((userData?['antPoint'] ?? 100) as num).toInt();
    }
    userRank.value = 0;
  }
}
