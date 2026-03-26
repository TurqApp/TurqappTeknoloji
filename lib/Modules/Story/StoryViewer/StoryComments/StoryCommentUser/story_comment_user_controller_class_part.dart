part of 'story_comment_user_controller.dart';

class StoryCommentUserController extends GetxController {
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
