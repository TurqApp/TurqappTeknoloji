import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';

class StoryLikesController extends GetxController {
  final StoryRepository _storyRepository = StoryRepository.ensure();
  RxList<String> list = <String>[].obs;
  var totalLike = 0.obs;
  Future<void> getData(String storyID) async {
    list.assignAll(await _storyRepository.fetchStoryLikeIds(storyID));
    totalLike.value = await _storyRepository.fetchStoryLikeCount(storyID);
  }
}
