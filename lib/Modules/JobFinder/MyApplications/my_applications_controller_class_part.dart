part of 'my_applications_controller.dart';

class MyApplicationsController extends GetxController {
  final UserSubcollectionRepository _subcollectionRepository =
      ensureUserSubcollectionRepository();
  final JobRepository _jobRepository = ensureJobRepository();
  RxList<JobApplicationModel> applications = <JobApplicationModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapApplicationsImpl());
  }
}
