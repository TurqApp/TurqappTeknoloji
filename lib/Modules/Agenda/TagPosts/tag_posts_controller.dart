import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';
import '../AgendaContent/agenda_content_controller.dart';
import 'tag_posts_repository.dart';

part 'tag_posts_controller_runtime_part.dart';
part 'tag_posts_controller_data_part.dart';

class TagPostsController extends GetxController {
  static String _normalizeTag(String tag) => tag.trim();
  static String? _activeTag;

  static TagPostsController? maybeFind({String? tag}) {
    final resolvedTag = tag ?? _activeTag;
    if (resolvedTag == null || resolvedTag.isEmpty) return null;
    final isRegistered = Get.isRegistered<TagPostsController>(tag: resolvedTag);
    if (!isRegistered) return null;
    return Get.find<TagPostsController>(tag: resolvedTag);
  }

  final String tag;
  final String controllerTag;
  final TagPostsRepository _repo;
  RxList<PostsModel> list = <PostsModel>[].obs;
  final scrollController = ScrollController();
  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? _pendingCenteredDocId;
  final Map<String, GlobalKey> _agendaKeys = {};

  TagPostsController({
    required this.tag,
    required this.controllerTag,
    TagPostsRepository? repository,
  }) : _repo = repository ?? TagPostsRepository();

  static TagPostsController ensure({required String tag}) {
    final tagKey = _normalizeTag(tag);
    _activeTag = tagKey;
    final existing = maybeFind(tag: tagKey);
    if (existing != null) return existing;
    return Get.put(
      TagPostsController(
        tag: tag,
        controllerTag: tagKey,
      ),
      tag: tagKey,
    );
  }

  @override
  void onClose() {
    _handleTagPostsClose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    _handleTagPostsInit();
  }
}
