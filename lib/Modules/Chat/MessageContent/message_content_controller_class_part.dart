part of 'message_content_controller.dart';

class MessageContentController extends GetxController {
  static MessageContentController ensure({
    required MessageModel model,
    required String mainID,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureMessageContentController(
        model: model,
        mainID: mainID,
        tag: tag,
        permanent: permanent,
      );

  static MessageContentController? maybeFind({String? tag}) =>
      _maybeFindMessageContentController(tag: tag);

  final MessageModel model;
  final String mainID;

  var nickname = "".obs;
  var avatarUrl = "".obs;

  var currentIndex = 0.obs;
  var showAllImages = false.obs;
  RxList<String> imageUrls = <String>[].obs;
  var postModel = Rx<PostsModel?>(null);

  MessageContentController({
    required this.model,
    required this.mainID,
  });

  var postNickname = "".obs;
  var postPfImage = "".obs;
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  @override
  void onInit() {
    super.onInit();
    _handleMessageContentInit(this);
  }
}
