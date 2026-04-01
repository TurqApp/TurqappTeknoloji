import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'story_highlight_model.dart';

class HighlightStoryViewerService {
  static Future<void> openHighlight({
    required String userId,
    required StoryHighlightModel highlight,
  }) async {
    try {
      final uniqueIds = highlight.storyIds.toSet().toList();
      if (uniqueIds.isEmpty) {
        AppSnackbar('common.info'.tr, 'story.highlight_no_stories'.tr);
        return;
      }

      List<StoryModel> stories = <StoryModel>[];

      final rowController = maybeFindStoryRowController();
      if (rowController != null) {
        final userModel =
            rowController.users.firstWhereOrNull((u) => u.userID == userId);
        if (userModel != null && userModel.stories.isNotEmpty) {
          final idSet = uniqueIds.toSet();
          stories = userModel.stories
              .where((s) => idSet.contains(s.id))
              .where((s) => s.userId == userId)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
      }

      if (stories.isEmpty) {
        final storyMap = await StoryRepository.ensure().fetchStoriesByIds(
          uniqueIds,
        );

        stories = storyMap.values.where((s) => s.userId == userId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      if (stories.isEmpty) {
        AppSnackbar('common.info'.tr, 'story.highlight_missing_stories'.tr);
        return;
      }

      final userData = await UserSummaryResolver.ensure().resolve(
        userId,
        preferCache: true,
      );
      final nickname = userData?.nickname.trim() ?? '';
      final fullName = userData?.displayName.trim() ?? '';

      final storyUser = StoryUserModel(
        nickname: nickname,
        avatarUrl: userData?.avatarUrl ?? '',
        fullName: fullName,
        userID: userId,
        stories: stories,
      );

      await Get.to(
        () => StoryViewer(
          startedUser: storyUser,
          storyOwnerUsers: [storyUser],
        ),
      );
    } catch (e) {
      AppSnackbar('common.error'.tr, 'story.highlight_open_failed'.tr);
    }
  }
}
