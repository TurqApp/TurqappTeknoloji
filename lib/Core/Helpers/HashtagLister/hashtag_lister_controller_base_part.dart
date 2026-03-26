part of 'hashtag_lister_controller.dart';

abstract class _HashtagListerControllerBase extends GetxController {
  final RxList<HashtagModel> hashtags = <HashtagModel>[].obs;
  final TopTagsRepository _topTagsRepository = ensureTopTagsRepository();

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
