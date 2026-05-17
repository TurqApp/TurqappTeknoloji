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

class _SavedItemsInteractionOverride {
  const _SavedItemsInteractionOverride({
    required this.isSelected,
    required this.createdAt,
    this.item,
  });

  final bool isSelected;
  final DateTime createdAt;
  final Map<String, dynamic>? item;
}

abstract class _SavedItemsControllerBase extends GetxController {
  static const Duration silentRefreshInterval = Duration(minutes: 5);
  static const Duration interactionOverrideTtl = Duration(minutes: 2);
  static final Map<String, _CachedSavedItemsList> _screenCache =
      <String, _CachedSavedItemsList>{};
  static final Map<String, _SavedItemsInteractionOverride>
      _interactionOverrides = <String, _SavedItemsInteractionOverride>{};
  static final Set<SavedItemsController> _liveControllers =
      <SavedItemsController>{};

  final _state = _SavedItemsControllerState();

  @override
  void onInit() {
    super.onInit();
    final controller = this as SavedItemsController;
    _liveControllers.add(controller);
    Future.microtask(() {
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
    final controller = this as SavedItemsController;
    _liveControllers.remove(controller);
    controller.pageController.dispose();
    super.onClose();
  }
}
