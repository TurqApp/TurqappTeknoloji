part of 'job_details_controller.dart';

class _JobDetailsControllerState {
  final userRepository = UserRepository.ensure();
  final userSummaryResolver = UserSummaryResolver.ensure();
  final cvRepository = CvRepository.ensure();
  final jobHomeSnapshotRepository = JobHomeSnapshotRepository.ensure();
  final jobRepository = JobRepository.ensure();
  final saved = false.obs;
  final basvuruldu = false.obs;
  final cvVar = false.obs;
  final nickname = ''.obs;
  final avatarUrl = kDefaultAvatarUrl.obs;
  final fullname = ''.obs;
  final list = <JobModel>[].obs;
  final reviews = <JobReviewModel>[].obs;
  final reviewUsers = <String, Map<String, dynamic>>{}.obs;
}

extension JobDetailsControllerFieldsPart on JobDetailsController {
  UserRepository get _userRepository => _state.userRepository;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  CvRepository get _cvRepository => _state.cvRepository;
  JobHomeSnapshotRepository get _jobHomeSnapshotRepository =>
      _state.jobHomeSnapshotRepository;
  JobRepository get _jobRepository => _state.jobRepository;
  RxBool get saved => _state.saved;
  RxBool get basvuruldu => _state.basvuruldu;
  RxBool get cvVar => _state.cvVar;
  RxString get nickname => _state.nickname;
  RxString get avatarUrl => _state.avatarUrl;
  RxString get fullname => _state.fullname;
  RxList<JobModel> get list => _state.list;
  RxList<JobReviewModel> get reviews => _state.reviews;
  RxMap<String, Map<String, dynamic>> get reviewUsers => _state.reviewUsers;
}
