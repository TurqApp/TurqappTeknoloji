part of 'my_job_ads_controller_library.dart';

const Duration _myJobAdsSilentRefreshInterval = Duration(minutes: 5);

abstract class _MyJobAdsControllerBase extends GetxController {
  final JobRepository _jobRepository = ensureJobRepository();
  final pageController = PageController();
  final isLoadingActive = true.obs;
  final isLoadingDeactive = true.obs;
  RxList<JobModel> active = <JobModel>[].obs;
  RxList<JobModel> deactive = <JobModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    (this as MyJobAdsController)._handleOnInit();
  }

  @override
  void onClose() {
    (this as MyJobAdsController)._handleOnClose();
    super.onClose();
  }
}
