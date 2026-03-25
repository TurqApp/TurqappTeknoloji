part of 'job_details_controller.dart';

class _JobDetailsControllerState {
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
