part of 'saved_items_controller.dart';

class SavedItemsController extends GetxController {
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
