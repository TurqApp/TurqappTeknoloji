import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';

class PostLikeContentController extends GetxController {
  var fullName = "".obs;
  var avatarUrl = "".obs;
  var nickname = "".obs;

  Future<void> getUserData(String userID) async {
    final summary = await UserRepository.ensure().getUser(
      userID,
      preferCache: true,
      cacheOnly: false,
    );
    if (summary == null) return;
    fullName.value = summary.displayName;
    avatarUrl.value = summary.avatarUrl;
    nickname.value = summary.preferredName;
  }
}
