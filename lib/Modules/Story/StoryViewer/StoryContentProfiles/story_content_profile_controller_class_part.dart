part of 'story_content_profile_controller.dart';

class StoryContentProfileController extends _StoryContentProfileControllerBase {
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
