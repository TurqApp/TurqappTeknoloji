import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'story_model.dart';

class StoryService {
  final StoryRepository _storyRepository = StoryRepository.ensure();

  /// Oturum açmış kullanıcıya ait hikâyeleri çeker
  Future<List<StoryModel>> fetchStoriesByCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu yok');
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
      throw Exception('Hikâye bulunamadı: $storyId');
    }
    return story;
  }
}
