part of 'story_content_profile_controller.dart';

class StoryContentProfileController extends GetxController {
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
