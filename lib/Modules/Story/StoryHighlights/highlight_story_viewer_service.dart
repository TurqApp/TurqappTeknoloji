import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
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
        AppSnackbar('Bilgi', 'Öne çıkarılanda hikaye yok.');
        return;
      }

      List<StoryModel> stories = <StoryModel>[];

      if (Get.isRegistered<StoryRowController>()) {
        final rowController = Get.find<StoryRowController>();
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

        stories = storyMap.values
            .where((s) => s.userId == userId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      if (stories.isEmpty) {
        AppSnackbar(
            'Bilgi', 'Bu öne çıkarılandaki hikayeler artık mevcut değil.');
        return;
      }

      final userData = await UserRepository.ensure().getUserRaw(userId) ??
          const <String, dynamic>{};
      final nickname = ((userData['nickname'] ?? userData['username'] ?? '')
              .toString()
              .trim())
          .toString();
      final firstName = (userData['firstName'] ?? '').toString().trim();
      final lastName = (userData['lastName'] ?? '').toString().trim();
      final displayName = (userData['displayName'] ?? '').toString().trim();
      final fullName = '$firstName $lastName'.trim().isNotEmpty
          ? '$firstName $lastName'.trim()
          : displayName;

      final storyUser = StoryUserModel(
        nickname: nickname,
        avatarUrl: resolveAvatarUrl(userData),
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
      AppSnackbar('Hata', 'Öne çıkarılan açılamadı. Lütfen tekrar deneyin.');
    }
  }
}
