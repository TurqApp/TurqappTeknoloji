part of 'story_content_profile_controller.dart';

abstract class _StoryContentProfileControllerBase extends GetxController {
  final RxString nickname = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxString fullName = ''.obs;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
}
