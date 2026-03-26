part of 'applications_controller.dart';

class ApplicationsController extends GetxController {
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ensureScholarshipRepository();
  final isLoading = true.obs;
  final applications = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }
}
