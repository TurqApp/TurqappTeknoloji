part of 'my_job_ads_controller.dart';

class MyJobAdsController extends GetxController {
  static MyJobAdsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyJobAdsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyJobAdsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyJobAdsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyJobAdsController>(tag: tag);
  }

  final JobRepository _jobRepository = JobRepository.ensure();
  final pageController = PageController();
  final isLoadingActive = true.obs;
  final isLoadingDeactive = true.obs;
  RxList<JobModel> active = <JobModel>[].obs;
  RxList<JobModel> deactive = <JobModel>[].obs;
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
