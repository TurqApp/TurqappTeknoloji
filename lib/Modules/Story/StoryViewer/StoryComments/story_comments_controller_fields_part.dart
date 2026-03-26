part of 'story_comments_controller.dart';

class _StoryCommentsControllerState {
  _StoryCommentsControllerState({
    required this.nickname,
    required this.storyID,
  });

  final StoryRepository storyRepository = StoryRepository.ensure();
  final RxList<StoryCommentModel> list = <StoryCommentModel>[].obs;
  final FocusNode commentFocus = FocusNode();
  final TextEditingController commentTextfield = TextEditingController();
  final String nickname;
  final String storyID;
  String? controllerTag;
  final RxInt totalComment = 0.obs;
  final RxString selectedGifUrl = ''.obs;
  final RxString lastSuccessfulCommentText = ''.obs;
  final RxString lastSuccessfulCommentGif = ''.obs;
}

extension StoryCommentsControllerFieldsPart on StoryCommentsController {
  StoryRepository get _storyRepository => _state.storyRepository;
  RxList<StoryCommentModel> get list => _state.list;
  FocusNode get commentFocus => _state.commentFocus;
  TextEditingController get commentTextfield => _state.commentTextfield;
  String get nickname => _state.nickname;
  String get storyID => _state.storyID;
  String? get controllerTag => _state.controllerTag;
  set controllerTag(String? value) => _state.controllerTag = value;
  RxInt get totalComment => _state.totalComment;
  RxString get selectedGifUrl => _state.selectedGifUrl;
  RxString get lastSuccessfulCommentText => _state.lastSuccessfulCommentText;
  RxString get lastSuccessfulCommentGif => _state.lastSuccessfulCommentGif;
  String get _currentUserId => _storyCommentsCurrentUserId();
}
