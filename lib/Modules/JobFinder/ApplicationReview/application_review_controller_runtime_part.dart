part of 'application_review_controller.dart';

extension ApplicationReviewControllerRuntimeX on ApplicationReviewController {
  Future<void> _handleOnInit() async {
    final cached = await _jobRepository.fetchApplications(
      jobDocID,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      applicants.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'jobs:applications_review:$jobDocID',
        minInterval: ApplicationReviewController._silentRefreshInterval,
      )) {
        unawaited(loadApplicants(silent: true, forceRefresh: true));
      }
      return;
    }
    await loadApplicants();
  }

  Future<void> loadApplicants({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _loadApplicantsImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> _loadApplicantsImpl({
    required bool silent,
    required bool forceRefresh,
  }) async {
    if (!silent) {
      isLoading.value = true;
    }
    try {
      applicants.value = await _jobRepository.fetchApplications(
        jobDocID,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      SilentRefreshGate.markRefreshed('jobs:applications_review:$jobDocID');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getApplicantCV(String userID) =>
      _getApplicantCVImpl(userID);

  Future<Map<String, dynamic>?> _getApplicantCVImpl(String userID) async {
    if (cvCache.containsKey(userID)) return cvCache[userID];
    try {
      final data = await _cvRepository.getCv(userID, preferCache: true);
      if (data != null) {
        if (cvCache.length >= ApplicationReviewController._maxCacheSize) {
          final oldestKey = cvCache.keys.first;
          cvCache.remove(oldestKey);
        }
        cvCache[userID] = data;
        return data;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getApplicantProfile(String userID) =>
      _getApplicantProfileImpl(userID);

  Future<Map<String, dynamic>?> _getApplicantProfileImpl(String userID) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      return summary?.toMap();
    } catch (_) {}
    return null;
  }

  Future<void> updateStatus(String userID, String newStatus) =>
      _updateStatusImpl(userID, newStatus);

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
