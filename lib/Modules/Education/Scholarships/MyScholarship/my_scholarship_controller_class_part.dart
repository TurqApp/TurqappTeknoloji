part of 'my_scholarship_controller.dart';

class MyScholarshipController extends GetxController {
  static MyScholarshipController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(MyScholarshipController(), tag: tag, permanent: permanent);
  }

  static MyScholarshipController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<MyScholarshipController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyScholarshipController>(tag: tag);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  var isLoading = true.obs;
  final myScholarships = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapMyScholarships());
  }

  Future<void> _bootstrapMyScholarships() =>
      MyScholarshipControllerRuntimePart(this).bootstrapMyScholarships();

  Future<void> fetchMyScholarships({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      MyScholarshipControllerRuntimePart(this).fetchMyScholarships(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<List<Map<String, dynamic>>> _buildScholarshipCards(
    List<Map<String, dynamic>> rawScholarships, {
    bool userCacheOnly = false,
  }) =>
      MyScholarshipControllerRuntimePart(this).buildScholarshipCards(
        rawScholarships,
        userCacheOnly: userCacheOnly,
      );
}
