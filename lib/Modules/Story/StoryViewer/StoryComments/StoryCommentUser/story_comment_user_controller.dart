import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';

class StoryCommentUserController extends GetxController {
  var nickname = "".obs;
  var avatarUrl = "".obs;
  var fullName = "".obs;

  Future<void> getUserData(String userID) async {
    final summary = await UserRepository.ensure().getUser(
      userID,
      preferCache: true,
      cacheOnly: false,
    );
    if (summary == null) return;
    nickname.value = summary.preferredName;
    fullName.value = summary.displayName;
    avatarUrl.value = summary.avatarUrl;
  }
}
