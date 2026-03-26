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

SavedJobsController ensureSavedJobsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindSavedJobsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SavedJobsController(),
    tag: tag,
    permanent: permanent,
  );
}

SavedJobsController? maybeFindSavedJobsController({String? tag}) {
  final isRegistered = Get.isRegistered<SavedJobsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SavedJobsController>(tag: tag);
}
