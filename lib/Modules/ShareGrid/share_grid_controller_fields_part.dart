part of 'share_grid_controller_library.dart';

class _ShareGridControllerState {
  _ShareGridControllerState({
    required this.postType,
    required this.postID,
  });

  final String postID;
  final String postType;
  final TextEditingController search = TextEditingController();
  final RxList<OgrenciModel> followings = <OgrenciModel>[].obs;
  final Rx<OgrenciModel?> selectedUser = Rx<OgrenciModel?>(null);
  final Rx<FocusNode> searchFocus = FocusNode().obs;
  Timer? searchDebounce;
  late final ChatListingController chatListingController =
      ChatListingController.maybeFind() ?? ChatListingController.ensure();
  final UserRepository userRepository = UserRepository.ensure();
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final ConversationRepository conversationRepository =
      ConversationRepository.ensure();
  final VisibilityPolicyService visibilityPolicy =
      VisibilityPolicyService.ensure();
}

extension ShareGridControllerFieldsPart on ShareGridController {
  String get postID => _state.postID;
  String get postType => _state.postType;
  TextEditingController get search => _state.search;
  RxList<OgrenciModel> get followings => _state.followings;
  Rx<OgrenciModel?> get selectedUser => _state.selectedUser;
  Rx<FocusNode> get searchFocus => _state.searchFocus;
  Timer? get _searchDebounce => _state.searchDebounce;
  set _searchDebounce(Timer? value) => _state.searchDebounce = value;
  ChatListingController get chatListingController =>
      _state.chatListingController;
  UserRepository get _userRepository => _state.userRepository;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  ConversationRepository get _conversationRepository =>
      _state.conversationRepository;
  VisibilityPolicyService get _visibilityPolicy => _state.visibilityPolicy;
}
