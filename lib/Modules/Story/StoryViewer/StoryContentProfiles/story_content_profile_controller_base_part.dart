part of 'story_content_profile_controller.dart';

abstract class _StoryContentProfileControllerBase extends GetxController {
  final RxString nickname = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxString fullName = ''.obs;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
}

class StoryContentProfileController extends _StoryContentProfileControllerBase {
  Future<void> getUserData(String userID) async {
    final summary =
        await _userSummaryResolver.resolve(userID, preferCache: true);
    if (summary == null) return;
    nickname.value = summary.preferredName;
    fullName.value = summary.displayName;
    avatarUrl.value = summary.avatarUrl;
  }
}
