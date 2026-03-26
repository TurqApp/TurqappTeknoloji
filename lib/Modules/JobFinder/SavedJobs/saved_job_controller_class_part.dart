part of 'saved_job_controller.dart';

class SavedJobsController extends GetxController {
  final JobRepository _jobRepository = JobRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  RxList<JobModel> list = <JobModel>[].obs;
  RxBool isLoading = false.obs;
  static const int _whereInChunkSize = 10;
  Position? _lastResolvedPosition;

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }
}
