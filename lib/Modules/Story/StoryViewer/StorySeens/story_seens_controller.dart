import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';

class StorySeensController extends GetxController {
  RxList<String> list = <String>[].obs;
  var totalSeen = 0.obs;
  final StoryRepository _storyRepository = StoryRepository.ensure();

  Future<void> getData(String storyID) async {
    try {
      list.assignAll(await _storyRepository.fetchStoryViewerIds(storyID));
    } catch (e) {
      print("Görüntüleme listesi alınamadı: $e");
      list.clear();
    }

    try {
      totalSeen.value = await _storyRepository.fetchStoryViewerCount(storyID);
    } catch (e) {
      print("Toplam görülme alınamadı: $e");
      totalSeen.value = 0;
    }
  }
}
