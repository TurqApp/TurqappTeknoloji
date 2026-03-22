import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';

class StorySeensController extends GetxController {
  static StorySeensController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      StorySeensController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static StorySeensController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<StorySeensController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<StorySeensController>(tag: tag);
  }

  RxList<String> list = <String>[].obs;
  var totalSeen = 0.obs;
  final StoryRepository _storyRepository = StoryRepository.ensure();

  Future<void> getData(String storyID) async {
    try {
      list.assignAll(await _storyRepository.fetchStoryViewerIds(storyID));
    } catch (_) {
      list.clear();
    }

    try {
      totalSeen.value = await _storyRepository.fetchStoryViewerCount(storyID);
    } catch (_) {
      totalSeen.value = 0;
    }
  }
}
