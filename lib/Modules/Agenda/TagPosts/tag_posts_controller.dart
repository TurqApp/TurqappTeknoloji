import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'tag_posts_repository.dart';

class TagPostsController extends GetxController {
  final String tag;
  final TagPostsRepository _repo;
  RxList<PostsModel> list = <PostsModel>[].obs;
  final scrollController = ScrollController();
  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  final Map<int, GlobalKey> _agendaKeys = {};

  TagPostsController({required this.tag, TagPostsRepository? repository})
      : _repo = repository ?? TagPostsRepository();

  @override
  void onInit() {
    super.onInit();
    getPosts();
  }

  // Başındaki #’den sonraki ilk harfi büyük yapar
  String capitalizeAfterHash(String tag) {
    if (tag.startsWith('#') && tag.length > 1) {
      return '#${tag[1].toUpperCase()}${tag.substring(2)}';
    } else if (tag.isNotEmpty) {
      return tag[0].toUpperCase() + tag.substring(1);
    }
    return tag;
  }

  Future<void> getPosts() async {
    final fetchedPosts = await _repo.fetchByTag(tag);
    fetchedPosts.shuffle();
    list.assignAll(fetchedPosts);
  }

  GlobalKey getAgendaKey(int index) {
    return _agendaKeys.putIfAbsent(
      index,
      () => GlobalObjectKey('tag_post_$index'),
    );
  }

  void updateVisibleIndexByPosition(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topThreshold = screenHeight * 0.33;
    final bottomThreshold = screenHeight * 0.66;

    for (int i = 0; i < list.length; i++) {
      final key = getAgendaKey(i);
      final ctx = key.currentContext;
      if (ctx == null) continue;

      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize || !box.attached) continue;

      final position = box.localToGlobal(Offset.zero).dy;
      final height = box.size.height;
      final center = position + height / 2;

      if (center > topThreshold && center < bottomThreshold) {
        centeredIndex.value = i;
        currentVisibleIndex.value = i;
        lastCenteredIndex = i;
        break;
      }
    }
  }
}
