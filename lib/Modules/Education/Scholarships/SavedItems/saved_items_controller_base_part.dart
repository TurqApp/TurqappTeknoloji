part of 'saved_items_controller_library.dart';

class _SavedItemsControllerState {
  final isLoading = false.obs;
  final likedScholarships = <Map<String, dynamic>>[].obs;
  final bookmarkedScholarships = <Map<String, dynamic>>[].obs;
  final selectedTabIndex = 0.obs;
  bool showOnlySelectedTab = false;
  bool configured = false;
  final pageController = PageController();
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final ScholarshipRepository scholarshipRepository =
      ensureScholarshipRepository();
}

class _CachedSavedItemsList {
  const _CachedSavedItemsList({
    required this.items,
    required this.cachedAt,
  });

  final List<Map<String, dynamic>> items;
  final DateTime cachedAt;
}

abstract class _SavedItemsControllerBase extends GetxController {
  static const Duration silentRefreshInterval = Duration(minutes: 5);
  static final Map<String, _CachedSavedItemsList> _screenCache =
      <String, _CachedSavedItemsList>{};

  final _state = _SavedItemsControllerState();

  @override
  void onInit() {
    super.onInit();
    Future.microtask(() {
      final controller = this as SavedItemsController;
      if (!controller._state.configured) {
        controller.configureView(
          initialTabIndex: 0,
          showOnlySelectedTab: false,
        );
      }
    });
  }

  @override
  void onClose() {
    (this as SavedItemsController).pageController.dispose();
    super.onClose();
  }
}
