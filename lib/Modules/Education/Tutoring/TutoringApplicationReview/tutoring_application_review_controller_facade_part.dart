part of 'tutoring_application_review_controller.dart';

extension TutoringApplicationReviewControllerFacadePart
    on TutoringApplicationReviewController {
  Future<void> loadApplicants() =>
      _TutoringApplicationReviewControllerActionsX(this).loadApplicants();

  Future<Map<String, dynamic>?> getApplicantProfile(String userID) =>
      _TutoringApplicationReviewControllerActionsX(this)
          .getApplicantProfile(userID);

  Future<void> updateStatus(String userID, String newStatus) =>
      _TutoringApplicationReviewControllerActionsX(this)
          .updateStatus(userID, newStatus);
}
