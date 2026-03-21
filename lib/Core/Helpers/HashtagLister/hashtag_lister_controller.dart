import 'package:get/get.dart';

import '../../../Models/hashtag_model.dart';
import '../../../Modules/Agenda/TopTags/top_tags_repository.dart';

class HashtagListerController extends GetxController {
  static HashtagListerController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      HashtagListerController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static HashtagListerController? maybeFind({String? tag}) {
    if (!Get.isRegistered<HashtagListerController>(tag: tag)) return null;
    return Get.find<HashtagListerController>(tag: tag);
  }

  RxList<HashtagModel> hashtags = <HashtagModel>[].obs;
  final TopTagsRepository _topTagsRepository = TopTagsRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _loadHashtags();
  }

  Future<void> _loadHashtags() async {
    final items = await _topTagsRepository.fetchTrendingTags(
      resultLimit: 20,
      preferCache: true,
      forceRefresh: false,
    );
    hashtags.assignAll(items);
  }
}
