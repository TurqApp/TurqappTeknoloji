part of 'deleted_stories_controller.dart';

class _DeletedStoriesControllerState {
  final RxList<StoryModel> list = <StoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, int> deletedAtById = <String, int>{}.obs;
  final RxMap<String, String> deleteReasonById = <String, String>{}.obs;
  final PageController pageController = PageController();
  final StoryRepository storyRepository = StoryRepository.ensure();
  final CurrentUserService userService = CurrentUserService.instance;
}

extension DeletedStoriesControllerFieldsPart on DeletedStoriesController {
  RxList<StoryModel> get list => _state.list;
  RxBool get isLoading => _state.isLoading;
  RxMap<String, int> get deletedAtById => _state.deletedAtById;
  RxMap<String, String> get deleteReasonById => _state.deleteReasonById;
  PageController get pageController => _state.pageController;
  StoryRepository get _storyRepository => _state.storyRepository;
  CurrentUserService get _userService => _state.userService;
  String get _currentUid => _userService.effectiveUserId;
}
