part of 'tutoring_detail_controller.dart';

extension _TutoringDetailControllerRuntimeX on TutoringDetailController {
  void bootstrap(TutoringModel tutoringData) {
    fetchTutoringDetail(tutoringData.docID);
    fetchUserData(tutoringData.userID);
    checkBasvuru(tutoringData.docID);
    getSimilar(tutoringData.brans, tutoringData.docID);
    fetchReviews(tutoringData.docID);
    incrementViewCount(tutoringData.docID, tutoringData.userID);
  }

  Future<void> fetchUserData(String userID) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary != null) {
        users[userID] = summary.toMap();
      }
    } catch (_) {}
  }

  Future<void> fetchTutoringDetail(String docID) async {
    isLoading.value = true;
    try {
      final document = await _tutoringRepository.fetchById(
        docID,
        allowExpired: true,
      );
      if (document != null) {
        tutoring.value = document;
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkBasvuru(String docID) async {
    try {
      final uid = _uid;
      if (uid.isEmpty) return;
      basvuruldu.value = await _tutoringRepository.hasApplication(docID, uid);
    } catch (_) {
      basvuruldu.value = false;
    }
  }

  Future<void> incrementViewCount(String docID, String ownerUID) async {
    try {
      final uid = _uid;
      if (uid.isEmpty || uid == ownerUID) return;
      await _tutoringRepository.incrementViewCount(docID);
    } catch (_) {}
  }

  Future<void> getSimilar(String brans, String currentDocID) async {
    try {
      final items = await _tutoringRepository.fetchSimilarByBranch(
        brans,
        currentDocID,
      );

      final userIds = items.map((t) => t.userID).toSet();
      final toFetch =
          userIds.where((id) => !similarUsers.containsKey(id)).toList();
      if (toFetch.isNotEmpty) {
        for (var i = 0; i < toFetch.length; i += 30) {
          final batch = toFetch.skip(i).take(30).toList();
          final summaries = await _userSummaryResolver.resolveMany(batch);
          for (final entry in summaries.entries) {
            similarUsers[entry.key] = entry.value.toMap();
          }
        }
      }

      similarList.assignAll(items);
    } catch (_) {}
  }
}
