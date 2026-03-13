import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';

class CreateChatContentController extends GetxController {
  var nickname = "".obs;
  var fullName = "".obs;
  var avatarUrl = "".obs;
  String userID;
  CreateChatContentController({required this.userID});
  @override
  void onInit() {
    super.onInit();
    unawaited(_loadUser());
  }

  Future<void> _loadUser() async {
    final user = await UserRepository.ensure().getUser(
      userID,
      preferCache: true,
      cacheOnly: false,
    );
    if (user == null) return;
    nickname.value = user.nickname.isNotEmpty
        ? user.nickname
        : (user.username.isNotEmpty ? user.username : user.displayName);
    avatarUrl.value = user.avatarUrl;
    fullName.value = user.displayName;
  }
}
