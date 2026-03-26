part of 'saved_job_controller.dart';

class SavedJobsController extends GetxController {
  static SavedJobsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SavedJobsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static SavedJobsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SavedJobsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SavedJobsController>(tag: tag);
  }

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
