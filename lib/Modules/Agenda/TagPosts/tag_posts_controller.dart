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

  void updateVisibleIndexByPosition(ScrollController controller) {
    if (!controller.hasClients || list.isEmpty) return;
    final position = controller.position;
    if (position.pixels <= 0) {
      centeredIndex.value = 0;
      currentVisibleIndex.value = 0;
      lastCenteredIndex = 0;
      return;
    }
    final estimatedItemExtent = (position.viewportDimension * 0.74).clamp(
      320.0,
      680.0,
    );
    final nextIndex = (((position.pixels + position.viewportDimension * 0.25) /
                estimatedItemExtent)
            .floor())
        .clamp(0, list.length - 1);
    centeredIndex.value = nextIndex;
    currentVisibleIndex.value = nextIndex;
    lastCenteredIndex = nextIndex;
  }
}
