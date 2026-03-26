part of 'tag_posts_controller.dart';

extension TagPostsControllerRuntimePart on TagPostsController {
  void _handleTagPostsInit() {
    getPosts();
  }

  void _handleTagPostsClose() {
    if (_activeTagPostsControllerTag == controllerTag) {
      _activeTagPostsControllerTag = null;
    }
  }

  String capitalizeAfterHash(String tag) {
    if (tag.startsWith('#') && tag.length > 1) {
      return '#${tag[1].toUpperCase()}${tag.substring(2)}';
    } else if (tag.isNotEmpty) {
      return tag[0].toUpperCase() + tag.substring(1);
    }
    return tag;
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
