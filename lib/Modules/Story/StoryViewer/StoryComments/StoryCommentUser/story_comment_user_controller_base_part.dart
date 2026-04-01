part of 'story_comment_user_controller.dart';

abstract class _StoryCommentUserControllerBase extends GetxController {
  final RxString nickname = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxString fullName = ''.obs;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
}

class StoryCommentUserController extends _StoryCommentUserControllerBase {
  Future<void> getUserData(String userID) async {
    final summary =
        await _userSummaryResolver.resolve(userID, preferCache: true);
    if (summary == null) return;
    nickname.value = summary.preferredName;
    fullName.value = summary.displayName;
    avatarUrl.value = summary.avatarUrl;
  }
}
