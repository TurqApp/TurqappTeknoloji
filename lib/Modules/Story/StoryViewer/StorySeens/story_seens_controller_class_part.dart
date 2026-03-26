part of 'story_seens_controller.dart';

class StorySeensController extends GetxController {
  final RxList<String> list = <String>[].obs;
  final totalSeen = 0.obs;
  final StoryRepository _storyRepository = StoryRepository.ensure();
}
