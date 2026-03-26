part of 'saved_items_controller_library.dart';

class _SavedItemsControllerState {
  final isLoading = false.obs;
  final likedScholarships = <Map<String, dynamic>>[].obs;
  final bookmarkedScholarships = <Map<String, dynamic>>[].obs;
  final selectedTabIndex = 0.obs;
  final pageController = PageController();
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final ScholarshipRepository scholarshipRepository =
      ensureScholarshipRepository();
}

abstract class _SavedItemsControllerBase extends GetxController {
  static const Duration silentRefreshInterval = Duration(minutes: 5);

  final _state = _SavedItemsControllerState();
}
