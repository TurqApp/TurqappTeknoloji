import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';

class StoryContentProfileController extends GetxController {
  static StoryContentProfileController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      StoryContentProfileController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static StoryContentProfileController? maybeFind({String? tag}) {
    if (!Get.isRegistered<StoryContentProfileController>(tag: tag)) {
      return null;
    }
    return Get.find<StoryContentProfileController>(tag: tag);
  }

  var nickname = "".obs;
  var avatarUrl = "".obs;
  var fullName = "".obs;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  Future<void> getUserData(String userID) async {
    final summary = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    if (summary == null) return;
    nickname.value = summary.preferredName;
    fullName.value = summary.displayName;
    avatarUrl.value = summary.avatarUrl;
  }
}
