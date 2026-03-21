import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';
import '../AgendaContent/agenda_content_controller.dart';
import 'tag_posts_repository.dart';

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
    if (_activeTag == controllerTag) {
      _activeTag = null;
    }
    super.onClose();
  }

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

  String agendaInstanceTag(String docId) => 'tag_post_$docId';

  GlobalKey getAgendaKey({required String docId}) {
    return _agendaKeys.putIfAbsent(
      docId,
      () => GlobalObjectKey(agendaInstanceTag(docId)),
    );
  }

  void disposeAgendaContentController(String docId) {
    final tag = agendaInstanceTag(docId);
    if (AgendaContentController.maybeFind(tag: tag) != null) {
      Get.delete<AgendaContentController>(tag: tag, force: true);
    }
  }

  void updateVisibleIndexByPosition(ScrollController controller) {
    if (!controller.hasClients || list.isEmpty) return;
    final position = controller.position;
    if (position.pixels <= 0) {
      centeredIndex.value = 0;
      currentVisibleIndex.value = 0;
      lastCenteredIndex = 0;
      capturePendingCenteredEntry(preferredIndex: 0);
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
    if (lastCenteredIndex != null &&
        lastCenteredIndex != nextIndex &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < list.length) {
      disposeAgendaContentController(list[lastCenteredIndex!].docID);
    }
    centeredIndex.value = nextIndex;
    currentVisibleIndex.value = nextIndex;
    lastCenteredIndex = nextIndex;
    capturePendingCenteredEntry(preferredIndex: nextIndex);
  }

  int resolveResumeCenteredIndex() {
    if (list.isEmpty) return -1;
    final pendingDocId = _pendingCenteredDocId;
    if (pendingDocId != null && pendingDocId.isNotEmpty) {
      final mapped = list.indexWhere((post) => post.docID == pendingDocId);
      if (mapped >= 0) return mapped;
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < list.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < list.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  void resumeCenteredPost() {
    final target = resolveResumeCenteredIndex();
    if (target < 0 || target >= list.length) return;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    lastCenteredIndex = target;
  }

  void capturePendingCenteredEntry({int? preferredIndex, PostsModel? model}) {
    if (model != null) {
      final docId = model.docID.trim();
      _pendingCenteredDocId = docId.isEmpty ? null : docId;
      return;
    }
    final candidateIndex = preferredIndex ??
        (currentVisibleIndex.value >= 0
            ? currentVisibleIndex.value
            : lastCenteredIndex);
    if (candidateIndex == null ||
        candidateIndex < 0 ||
        candidateIndex >= list.length) {
      _pendingCenteredDocId = null;
      return;
    }
    final docId = list[candidateIndex].docID.trim();
    _pendingCenteredDocId = docId.isEmpty ? null : docId;
  }
}
