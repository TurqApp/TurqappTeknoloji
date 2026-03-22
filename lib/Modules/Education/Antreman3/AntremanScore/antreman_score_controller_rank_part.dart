part of 'antreman_score_controller.dart';

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
    if (uid.isNotEmpty) {
      unawaited(_computeUserRank(uid));
    }
  }

  Future<void> _computeUserRank(String currentUserId) async {
    try {
      var rank = 1;
      DocumentSnapshot<Map<String, dynamic>>? lastDocument;
      const pageSize = 400;
      while (true) {
        final page = await _antremanRepository.fetchLeaderboardPage(
          monthKey: _monthKey,
          pageSize: pageSize,
          lastDocument: lastDocument,
        );
        if (page.isEmpty) break;

        final eligibleDocs = page.where((entry) {
          return _isEligibleEntry(entry);
        }).toList()
          ..sort(_compareEntries);

        for (final doc in eligibleDocs) {
          if (doc['userID'] == currentUserId) {
            userRank.value = rank;
            return;
          }
          rank++;
        }

        final last = page.last['_doc'];
        if (last is DocumentSnapshot<Map<String, dynamic>>) {
          lastDocument = last;
        } else {
          break;
        }
      }
    } catch (e) {
      log('Sıralama hesaplanamadı: $e');
    }
  }
}
