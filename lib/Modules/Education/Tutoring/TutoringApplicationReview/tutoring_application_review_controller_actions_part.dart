part of 'tutoring_application_review_controller.dart';

extension _TutoringApplicationReviewControllerActionsX
    on TutoringApplicationReviewController {
  Future<void> _loadApplicants() async {
    isLoading.value = true;
    try {
      applicants.value = await _tutoringRepository.fetchApplications(
        tutoringDocID,
        preferCache: true,
      );
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> _getApplicantProfile(String userID) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      return summary?.toMap();
    } catch (_) {}
    return null;
  }

  Future<void> _updateStatus(String userID, String newStatus) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _tutoringRepository.updateApplicationStatus(
        tutoringId: tutoringDocID,
        userId: userID,
        status: newStatus,
      );

      final index = applicants.indexWhere((a) => a.userID == userID);
      if (index != -1) {
        final old = applicants[index];
        applicants[index] = TutoringApplicationModel(
          tutoringDocID: old.tutoringDocID,
          userID: old.userID,
          tutoringTitle: old.tutoringTitle,
          tutorName: old.tutorName,
          tutorImage: old.tutorImage,
          status: newStatus,
          timeStamp: old.timeStamp,
          statusUpdatedAt: now,
          note: old.note,
        );
        applicants.refresh();
      }
    } catch (_) {}
  }
}
