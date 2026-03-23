part of 'application_review_controller.dart';

extension ApplicationReviewControllerDataPart on ApplicationReviewController {
  Future<void> _bootstrapApplicantsImpl() async {
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
}
