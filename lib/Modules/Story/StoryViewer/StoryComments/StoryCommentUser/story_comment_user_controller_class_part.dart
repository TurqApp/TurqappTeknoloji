part of 'story_comment_user_controller.dart';

class StoryCommentUserController extends _StoryCommentUserControllerBase {
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
