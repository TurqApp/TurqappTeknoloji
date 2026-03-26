part of 'applications_controller.dart';

class ApplicationsController extends GetxController {
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ensureScholarshipRepository();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final isLoading = true.obs;
  final applications = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }
}
