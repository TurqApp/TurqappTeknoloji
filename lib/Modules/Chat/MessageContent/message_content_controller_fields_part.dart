part of 'message_content_controller.dart';

class _MessageContentControllerState {
  _MessageContentControllerState({
    required this.model,
    required this.mainID,
  });

  final MessageModel model;
  final String mainID;
  final RxString nickname = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxInt currentIndex = 0.obs;
  final RxBool showAllImages = false.obs;
  final RxList<String> imageUrls = <String>[].obs;
  final Rx<PostsModel?> postModel = Rx<PostsModel?>(null);
  final RxString postNickname = ''.obs;
  final RxString postPfImage = ''.obs;
  final ConversationRepository conversationRepository =
      ConversationRepository.ensure();
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
}

extension MessageContentControllerFieldsPart on MessageContentController {
  MessageModel get model => _state.model;
  String get mainID => _state.mainID;
  RxString get nickname => _state.nickname;
  RxString get avatarUrl => _state.avatarUrl;
  RxInt get currentIndex => _state.currentIndex;
  RxBool get showAllImages => _state.showAllImages;
  RxList<String> get imageUrls => _state.imageUrls;
  Rx<PostsModel?> get postModel => _state.postModel;
  RxString get postNickname => _state.postNickname;
  RxString get postPfImage => _state.postPfImage;
  ConversationRepository get _conversationRepository =>
      _state.conversationRepository;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
}
