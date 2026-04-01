part of 'tutoring_detail_controller_library.dart';

extension TutoringDetailControllerReviewsPart on TutoringDetailController {
  Future<void> fetchReviews(String docID) async {
    try {
      final items = await _tutoringRepository.fetchReviews(docID);

      final userIds = items.map((r) => r.userID).toSet();
      final toFetch =
          userIds.where((id) => !reviewUsers.containsKey(id)).toList();
      if (toFetch.isNotEmpty) {
        for (var i = 0; i < toFetch.length; i += 30) {
          final batch = toFetch.skip(i).take(30).toList();
          final summaries = await _userSummaryResolver.resolveMany(batch);
          for (final entry in summaries.entries) {
            reviewUsers[entry.key] = entry.value.toMap();
          }
        }
      }

      reviews.assignAll(items);
    } catch (_) {}
  }

  Future<void> submitReview(String docID, int rating, String comment) async {
    final uid = _uid;
    if (uid.isEmpty) return;
    if (!await TextModerationService.ensureAllowed([comment])) return;

    try {
      await _tutoringRepository.submitReview(
        tutoringId: docID,
        userId: uid,
        rating: rating,
        comment: comment,
      );
      await fetchReviews(docID);
    } catch (_) {}
  }

  Future<void> deleteReview(String docID, String reviewID) async {
    try {
      await _tutoringRepository.deleteReview(
        tutoringId: docID,
        reviewId: reviewID,
      );
      await fetchReviews(docID);
    } catch (_) {}
  }
}
