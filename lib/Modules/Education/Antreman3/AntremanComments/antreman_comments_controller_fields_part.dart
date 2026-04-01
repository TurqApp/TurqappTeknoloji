part of 'antreman_comments_controller.dart';

class _AntremanCommentsControllerState {
  _AntremanCommentsControllerState(this.question);

  final QuestionBankModel question;
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final AntremanRepository antremanRepository = AntremanRepository.ensure();
  final String userID = CurrentUserService.instance.effectiveUserId;
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  final RxList<Comment> comments = <Comment>[].obs;
  final RxMap<String, List<Reply>> replies = <String, List<Reply>>{}.obs;
  final RxMap<String, bool> repliesVisible = <String, bool>{}.obs;
  final RxString replyingToCommentDocID = ''.obs;
  final TextEditingController commentController = TextEditingController();
  final Map<String, Map<String, dynamic>> userInfoCache = {};
  final RxString editingCommentDocID = ''.obs;
  final RxString editingReplyDocID = ''.obs;
  final RxBool isTextFieldNotEmpty = false.obs;
  final RxBool isLoading = true.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);
  final ImagePicker picker = ImagePicker();
}

extension AntremanCommentsControllerFieldsPart on AntremanCommentsController {
  QuestionBankModel get question => _state.question;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  AntremanRepository get _antremanRepository => _state.antremanRepository;
  String get userID => _state.userID;
  FocusNode get focusNode => _state.focusNode;
  ScrollController get scrollController => _state.scrollController;
  RxList<Comment> get comments => _state.comments;
  RxMap<String, List<Reply>> get replies => _state.replies;
  RxMap<String, bool> get repliesVisible => _state.repliesVisible;
  RxString get replyingToCommentDocID => _state.replyingToCommentDocID;
  TextEditingController get commentController => _state.commentController;
  Map<String, Map<String, dynamic>> get userInfoCache => _state.userInfoCache;
  RxString get editingCommentDocID => _state.editingCommentDocID;
  RxString get editingReplyDocID => _state.editingReplyDocID;
  RxBool get isTextFieldNotEmpty => _state.isTextFieldNotEmpty;
  RxBool get isLoading => _state.isLoading;
  Rx<File?> get selectedImage => _state.selectedImage;
  ImagePicker get picker => _state.picker;
}
