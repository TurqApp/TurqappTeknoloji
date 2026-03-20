import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'story_model.dart';

class StoryService {
  final StoryRepository _storyRepository = StoryRepository.ensure();

  /// Oturum açmış kullanıcıya ait hikâyeleri çeker
  Future<List<StoryModel>> fetchStoriesByCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('story.fetch_session_missing'.tr);
    }

    return _storyRepository.getStoriesForUser(
      user.uid,
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
