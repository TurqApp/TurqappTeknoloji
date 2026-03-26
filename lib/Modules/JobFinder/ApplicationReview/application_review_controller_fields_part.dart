part of 'application_review_controller.dart';

class _ApplicationReviewControllerState {
  _ApplicationReviewControllerState({required this.jobDocID});

  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final CvRepository cvRepository = CvRepository.ensure();
  final JobRepository jobRepository = JobRepository.ensure();
  final String jobDocID;
  final RxList<JobApplicationModel> applicants = <JobApplicationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, Map<String, dynamic>> cvCache =
      <String, Map<String, dynamic>>{}.obs;
}

extension ApplicationReviewControllerFieldsPart on ApplicationReviewController {
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  CvRepository get _cvRepository => _state.cvRepository;
  JobRepository get _jobRepository => _state.jobRepository;
  String get jobDocID => _state.jobDocID;
  RxList<JobApplicationModel> get applicants => _state.applicants;
  RxBool get isLoading => _state.isLoading;
  RxMap<String, Map<String, dynamic>> get cvCache => _state.cvCache;
}
