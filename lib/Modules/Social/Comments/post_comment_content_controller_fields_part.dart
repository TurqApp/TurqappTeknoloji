part of 'post_comment_content_controller.dart';

class _PostCommentContentControllerState {
  _PostCommentContentControllerState({
    required this.model,
    required this.postID,
    required this.commentControllerTag,
  });

  final PostCommentModel model;
  final String postID;
  final String commentControllerTag;
  final PostInteractionService interactionService =
      ensurePostInteractionService();
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final nickname = ''.obs;
  final avatarUrl = ''.obs;
  final likes = <String>[].obs;
  final replies = <SubCommentModel>[].obs;
  final replyNicknames = <String, String>{}.obs;
  final replyAvatarUrls = <String, String>{}.obs;
  StreamSubscription<List<SubCommentModel>>? replySub;
}

extension PostCommentContentControllerFieldsPart
    on PostCommentContentController {
  PostCommentModel get model => _state.model;
  String get postID => _state.postID;
  String get commentControllerTag => _state.commentControllerTag;
  PostInteractionService get _interactionService => _state.interactionService;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  RxString get nickname => _state.nickname;
  RxString get avatarUrl => _state.avatarUrl;
  RxList<String> get likes => _state.likes;
  RxList<SubCommentModel> get replies => _state.replies;
  RxMap<String, String> get replyNicknames => _state.replyNicknames;
  RxMap<String, String> get replyAvatarUrls => _state.replyAvatarUrls;
  StreamSubscription<List<SubCommentModel>>? get _replySub => _state.replySub;
  set _replySub(StreamSubscription<List<SubCommentModel>>? value) =>
      _state.replySub = value;
}
