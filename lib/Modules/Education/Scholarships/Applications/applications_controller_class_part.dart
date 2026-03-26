part of 'applications_controller.dart';

class ApplicationsController extends GetxController {
  static ApplicationsController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(ApplicationsController(), tag: tag, permanent: permanent);
  }

  static ApplicationsController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<ApplicationsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ApplicationsController>(tag: tag);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final isLoading = true.obs;
  final applications = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }
}
