import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/job_application_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'application_review_controller_data_part.dart';
part 'application_review_controller_actions_part.dart';

class ApplicationReviewController extends GetxController {
  static ApplicationReviewController ensure({
    required String jobDocID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ApplicationReviewController(jobDocID: jobDocID),
      tag: tag,
      permanent: permanent,
    );
  }

  static ApplicationReviewController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<ApplicationReviewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ApplicationReviewController>(tag: tag);
  }

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
    unawaited(_bootstrapApplicantsImpl());
  }

  Future<void> loadApplicants({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _loadApplicantsImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  static const int _maxCacheSize = 50;

  Future<Map<String, dynamic>?> getApplicantCV(String userID) =>
      _getApplicantCVImpl(userID);

  Future<Map<String, dynamic>?> getApplicantProfile(String userID) =>
      _getApplicantProfileImpl(userID);

  Future<void> updateStatus(String userID, String newStatus) =>
      _updateStatusImpl(userID, newStatus);
}
