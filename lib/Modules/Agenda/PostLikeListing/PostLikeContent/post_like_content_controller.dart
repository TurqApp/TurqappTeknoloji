import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';

class PostLikeContentController extends GetxController {
  var fullName = "".obs;
  var avatarUrl = "".obs;
  var nickname = "".obs;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  Future<void> getUserData(String userID) async {
    final summary = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    if (summary == null) return;
    fullName.value = summary.displayName;
    avatarUrl.value = summary.avatarUrl;
    nickname.value = summary.preferredName;
  }
}
