part of 'application_review_controller.dart';

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
    unawaited(_handleOnInit());
  }

  static const int _maxCacheSize = 50;
}
