part of 'deleted_stories_controller.dart';

class DeletedStoriesController extends GetxController {
  static DeletedStoriesController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(DeletedStoriesController());
  }

  static DeletedStoriesController? maybeFind() {
    final isRegistered = Get.isRegistered<DeletedStoriesController>();
    if (!isRegistered) return null;
    return Get.find<DeletedStoriesController>();
  }

  RxList<StoryModel> list = <StoryModel>[].obs;
  RxBool isLoading = false.obs;
  final RxMap<String, int> deletedAtById = <String, int>{}.obs;
  final RxMap<String, String> deleteReasonById = <String, String>{}.obs;
  final PageController pageController = PageController();
  final StoryRepository _storyRepository = StoryRepository.ensure();
  final CurrentUserService _userService = CurrentUserService.instance;
  String get _currentUid => _userService.effectiveUserId;

  @override
  void onInit() {
    super.onInit();
    _handleDeletedStoriesInit();
  }

  @override
  Future<void> refresh() async {
    await _handleDeletedStoriesRefresh();
  }

  void goToPage(int index) {
    _handleGoToPage(index);
  }

  @override
  void onClose() {
    _handleDeletedStoriesClose();
    super.onClose();
  }
}
