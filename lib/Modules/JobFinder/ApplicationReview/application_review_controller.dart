import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/job_application_model.dart';

class ApplicationReviewController extends GetxController {
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final CvRepository _cvRepository = CvRepository.ensure();
  final JobRepository _jobRepository = JobRepository.ensure();
  final String jobDocID;
  ApplicationReviewController({required this.jobDocID});

  RxList<JobApplicationModel> applicants = <JobApplicationModel>[].obs;
  var isLoading = false.obs;
  static const Duration _silentRefreshInterval = Duration(minutes: 3);

  final RxMap<String, Map<String, dynamic>> cvCache =
      <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapApplicants());
  }

  Future<void> _bootstrapApplicants() async {
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
        minInterval: _silentRefreshInterval,
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

  static const int _maxCacheSize = 50;

  Future<Map<String, dynamic>?> getApplicantCV(String userID) async {
    if (cvCache.containsKey(userID)) return cvCache[userID];
    try {
      final data = await _cvRepository.getCv(userID, preferCache: true);
      if (data != null) {
        // Eski cache'i temizle
        if (cvCache.length >= _maxCacheSize) {
          final oldestKey = cvCache.keys.first;
          cvCache.remove(oldestKey);
        }
        cvCache[userID] = data;
        return data;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getApplicantProfile(String userID) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      return summary?.toMap();
    } catch (_) {}
    return null;
  }

  Future<void> updateStatus(String userID, String newStatus) async {
    try {
      final actorUid = FirebaseAuth.instance.currentUser?.uid ?? '';
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
