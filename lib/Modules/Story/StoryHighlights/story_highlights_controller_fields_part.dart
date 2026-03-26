part of 'story_highlights_controller_library.dart';

class _StoryHighlightsControllerState {
  _StoryHighlightsControllerState({required this.userId});

  final String userId;
  final StoryHighlightsRepository repository =
      ensureStoryHighlightsRepository();
  final StoryRepository storyRepository = StoryRepository.ensure();
  final CurrentUserService userService = CurrentUserService.instance;
  final RxList<StoryHighlightModel> highlights = <StoryHighlightModel>[].obs;
  final RxBool isLoading = false.obs;
}

extension StoryHighlightsControllerFieldsPart on StoryHighlightsController {
  String get userId => _state.userId;
  StoryHighlightsRepository get _repository => _state.repository;
  StoryRepository get _storyRepository => _state.storyRepository;
  CurrentUserService get _userService => _state.userService;
  RxList<StoryHighlightModel> get highlights => _state.highlights;
  RxBool get isLoading => _state.isLoading;

  String get _ownerUid => userId.trim();

  bool get _canMutateOwnedHighlights {
    final ownerUid = _ownerUid;
    if (ownerUid.isEmpty) return false;
    final authUid = _userService.authUserId.trim();
    if (authUid.isEmpty) return false;
    return authUid == ownerUid;
  }
}
