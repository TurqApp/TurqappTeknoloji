import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/PostsModel.dart';
import 'TagPostsRepository.dart';

class TagPostsController extends GetxController {
  final String tag;
  final TagPostsRepository _repo;
  RxList<PostsModel> list = <PostsModel>[].obs;
  final scrollController = ScrollController();

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
    print(">>> Tag post araması başlıyor! [TAG: $tag]");
    final fetchedPosts = await _repo.fetchByTag(tag);
    fetchedPosts.shuffle();
    list.assignAll(fetchedPosts);
    print(">>> Tag sonuç: ${fetchedPosts.length}");
  }
}
