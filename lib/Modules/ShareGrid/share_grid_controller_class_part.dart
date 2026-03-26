part of 'share_grid_controller.dart';

class ShareGridController extends GetxController {
  static ShareGridController ensure({
    required String postType,
    required String postID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ShareGridController(postType: postType, postID: postID),
      tag: tag,
      permanent: permanent,
    );
  }

  static ShareGridController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<ShareGridController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ShareGridController>(tag: tag);
  }

  String postID;
  String postType;
  ShareGridController({required this.postType, required this.postID});
  TextEditingController search = TextEditingController();
  RxList<OgrenciModel> followings = <OgrenciModel>[].obs;
  var selectedUser = Rx<OgrenciModel?>(null);
  Rx<FocusNode> searchFocus = FocusNode().obs;
  late final ChatListingController chatListingController =
      ChatListingController.maybeFind() ?? ChatListingController.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();

  @override
  void onInit() {
    super.onInit();
    _handleShareGridInit();
  }

  @override
  void onClose() {
    _handleShareGridClose();
    super.onClose();
  }
}
