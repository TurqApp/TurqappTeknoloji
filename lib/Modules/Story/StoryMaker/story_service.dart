import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'story_model.dart';

class StoryService {
  final StoryRepository _storyRepository = StoryRepository.ensure();

  /// Oturum açmış kullanıcıya ait hikâyeleri çeker
  Future<List<StoryModel>> fetchStoriesByCurrentUser() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) {
      throw Exception('story.fetch_session_missing'.tr);
    }

    return _storyRepository.getStoriesForUser(
      userId,
      preferCache: true,
      includeDeleted: true,
    );
  }

  /// Belirli bir hikâyeyi ID’siyle çeker
  Future<StoryModel> fetchStoryById(String storyId) async {
    final story = await _storyRepository.fetchStoryById(
      storyId,
      preferCache: true,
    );
    if (story == null) {
      throw Exception('story.fetch_not_found'.trParams({'id': storyId}));
    }
    return story;
  }
}
