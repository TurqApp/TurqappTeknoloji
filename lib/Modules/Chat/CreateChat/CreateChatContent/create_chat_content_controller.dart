import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';

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
    if (!Get.isRegistered<CreateChatContentController>(tag: tag)) return null;
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
