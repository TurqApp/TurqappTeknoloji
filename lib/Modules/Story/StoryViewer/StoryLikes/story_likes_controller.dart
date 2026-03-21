import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';

class StoryLikesController extends GetxController {
  static StoryLikesController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      StoryLikesController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static StoryLikesController? maybeFind({String? tag}) {
    if (!Get.isRegistered<StoryLikesController>(tag: tag)) return null;
    return Get.find<StoryLikesController>(tag: tag);
  }

  final StoryRepository _storyRepository = StoryRepository.ensure();
  RxList<String> list = <String>[].obs;
  var totalLike = 0.obs;
  Future<void> getData(String storyID) async {
    list.assignAll(await _storyRepository.fetchStoryLikeIds(storyID));
    totalLike.value = await _storyRepository.fetchStoryLikeCount(storyID);
  }
}
