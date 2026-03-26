part of 'saved_job_controller_library.dart';

class SavedJobsController extends GetxController {
  final JobRepository _jobRepository = ensureJobRepository();
  RxList<JobModel> list = <JobModel>[].obs;
  RxBool isLoading = false.obs;
  Position? _lastResolvedPosition;

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }
}
