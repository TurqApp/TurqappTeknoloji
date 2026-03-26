part of 'my_applications_controller.dart';

class MyApplicationsController extends GetxController {
  static MyApplicationsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyApplicationsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyApplicationsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyApplicationsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyApplicationsController>(tag: tag);
  }

  final UserSubcollectionRepository _subcollectionRepository =
      ensureUserSubcollectionRepository();
  final JobRepository _jobRepository = JobRepository.ensure();
  RxList<JobApplicationModel> applications = <JobApplicationModel>[].obs;
  var isLoading = false.obs;
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapApplicationsImpl());
  }
}
