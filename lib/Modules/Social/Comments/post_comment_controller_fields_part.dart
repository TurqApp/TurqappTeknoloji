part of 'post_comment_controller_library.dart';

class _PostCommentControllerState {
  _PostCommentControllerState({
    required this.postID,
    required this.userID,
    required this.collection,
    this.onCommentCountChange,
  });

  final String postID;
  final String userID;
  final String collection;
  final Function(bool increment)? onCommentCountChange;
  String? controllerTag;
  final userService = CurrentUserService.instance;
  final interactionService = ensurePostInteractionService();
  final userSummaryResolver = UserSummaryResolver.ensure();
  final list = <PostCommentModel>[].obs;
  final pendingCommentIds = <String>{}.obs;
  final postUserNickname = ''.obs;
  final replyingToCommentId = ''.obs;
  final replyingToNickname = ''.obs;
  final selectedGifUrl = ''.obs;
  final lastSuccessfulCommentId = ''.obs;
  final lastSuccessfulSendText = ''.obs;
  final lastSuccessfulSendWasReply = false.obs;
  final lastDeletedCommentId = ''.obs;
  final lastDeletedCommentText = ''.obs;
  final pendingLocalComments = <String, PostCommentModel>{};
  StreamSubscription<List<PostCommentModel>>? commentSub;
}

extension PostCommentControllerFieldsPart on PostCommentController {
  String get postID => _state.postID;
  String get userID => _state.userID;
  String get collection => _state.collection;
  Function(bool increment)? get onCommentCountChange =>
      _state.onCommentCountChange;
  String? get controllerTag => _state.controllerTag;
  set controllerTag(String? value) => _state.controllerTag = value;
  CurrentUserService get userService => _state.userService;
  PostInteractionService get _interactionService => _state.interactionService;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  RxList<PostCommentModel> get list => _state.list;
  RxSet<String> get pendingCommentIds => _state.pendingCommentIds;
  RxString get postUserNickname => _state.postUserNickname;
  RxString get replyingToCommentId => _state.replyingToCommentId;
  RxString get replyingToNickname => _state.replyingToNickname;
  RxString get selectedGifUrl => _state.selectedGifUrl;
  RxString get lastSuccessfulCommentId => _state.lastSuccessfulCommentId;
  RxString get lastSuccessfulSendText => _state.lastSuccessfulSendText;
  RxBool get lastSuccessfulSendWasReply => _state.lastSuccessfulSendWasReply;
  RxString get lastDeletedCommentId => _state.lastDeletedCommentId;
  RxString get lastDeletedCommentText => _state.lastDeletedCommentText;
  Map<String, PostCommentModel> get _pendingLocalComments =>
      _state.pendingLocalComments;
  StreamSubscription<List<PostCommentModel>>? get _commentSub =>
      _state.commentSub;
  set _commentSub(StreamSubscription<List<PostCommentModel>>? value) =>
      _state.commentSub = value;
}
