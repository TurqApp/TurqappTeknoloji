part of 'story_comment_user_controller.dart';

abstract class _StoryCommentUserControllerBase extends GetxController {
  final RxString nickname = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxString fullName = ''.obs;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
}
