part of 'create_chat_content_controller.dart';

class CreateChatContentController extends GetxController {
  static CreateChatContentController ensure({
    required String userID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateChatContentController(userID: userID),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateChatContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<CreateChatContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateChatContentController>(tag: tag);
  }

  var nickname = "".obs;
  var fullName = "".obs;
  var avatarUrl = "".obs;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  String userID;
  CreateChatContentController({required this.userID});
  @override
  void onInit() {
    super.onInit();
    unawaited(_loadUser());
  }

  Future<void> _loadUser() async {
    final user = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    if (user == null) return;
    nickname.value = user.nickname.isNotEmpty
        ? user.nickname
        : (user.username.isNotEmpty ? user.username : user.displayName);
    avatarUrl.value = user.avatarUrl;
    fullName.value = user.displayName;
  }
}
