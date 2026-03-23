part of 'application_review_controller.dart';

extension ApplicationReviewControllerActionsPart
    on ApplicationReviewController {
  Future<void> _updateStatusImpl(String userID, String newStatus) async {
    try {
      final actorUid = CurrentUserService.instance.effectiveUserId;
      if (actorUid.isEmpty) {
        AppSnackbar(
          'common.error'.tr,
          'pasaj.job_finder.relogin_required'.tr,
        );
        return;
      }
      await _jobRepository.updateApplicationStatus(
        jobDocId: jobDocID,
        applicantUserId: userID,
        actorUid: actorUid,
        newStatus: newStatus,
      );

      final index = applicants.indexWhere((a) => a.userID == userID);
      if (index != -1) {
        final old = applicants[index];
        final now = DateTime.now().millisecondsSinceEpoch;
        applicants[index] = JobApplicationModel(
          jobDocID: old.jobDocID,
          userID: old.userID,
          jobTitle: old.jobTitle,
          companyName: old.companyName,
          companyLogo: old.companyLogo,
          applicantName: old.applicantName,
          applicantNickname: old.applicantNickname,
          applicantPfImage: old.applicantPfImage,
          status: newStatus,
          timeStamp: old.timeStamp,
          statusUpdatedAt: now,
          note: old.note,
        );
        applicants.refresh();
      }
      AppSnackbar(
        'common.success'.tr,
        'pasaj.job_finder.status_updated'.tr,
      );
      await loadApplicants(silent: true, forceRefresh: true);
    } catch (_) {
      AppSnackbar(
        'common.error'.tr,
        'pasaj.job_finder.status_update_failed'.tr,
      );
    }
  }
}
