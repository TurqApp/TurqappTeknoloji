part of 'saved_items_controller.dart';

class SavedItemsController extends GetxController {
  static SavedItemsController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(SavedItemsController(), tag: tag, permanent: permanent);
  }

  static SavedItemsController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<SavedItemsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SavedItemsController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final isLoading = false.obs;
  final likedScholarships = <Map<String, dynamic>>[].obs;
  final bookmarkedScholarships = <Map<String, dynamic>>[].obs;
  final selectedTabIndex = 0.obs;
  final pageController = PageController();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapSavedItems());
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
