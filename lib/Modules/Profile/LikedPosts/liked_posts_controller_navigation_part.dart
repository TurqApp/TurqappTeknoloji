part of 'liked_posts_controller_library.dart';

class _LikedPostsControllerNavigationPart {
  final LikedPostControllers controller;

  const _LikedPostsControllerNavigationPart(this.controller);

  void goToPage(int index) {
    controller.pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  GlobalKey getPostKey(String docId) {
    return controller._postKeys.putIfAbsent(
      docId,
      () => GlobalObjectKey('liked_post_$docId'),
    );
  }

  String agendaInstanceTag(String docId) => 'liked_post_$docId';

  void disposeAgendaContentController(String docId) {
    final tag = agendaInstanceTag(docId);
    if (AgendaContentController.maybeFind(tag: tag) != null) {
      Get.delete<AgendaContentController>(tag: tag, force: true);
    }
  }

  int resolveResumeCenteredIndex() {
    if (controller.all.isEmpty) return -1;
    final pendingDocId = controller._pendingCenteredDocId;
    if (pendingDocId != null && pendingDocId.isNotEmpty) {
      final pendingIndex = controller.all.indexWhere(
        (post) => post.docID.trim() == pendingDocId,
      );
      if (pendingIndex >= 0) {
        return pendingIndex;
      }
    }
    if (controller.lastCenteredIndex != null &&
        controller.lastCenteredIndex! >= 0 &&
        controller.lastCenteredIndex! < controller.all.length) {
      return controller.lastCenteredIndex!;
    }
    if (controller.centeredIndex.value >= 0 &&
        controller.centeredIndex.value < controller.all.length) {
      return controller.centeredIndex.value;
    }
    return 0;
  }

  void resumeCenteredPost() {
    final target = resolveResumeCenteredIndex();
    if (target < 0 || target >= controller.all.length) return;
    controller.lastCenteredIndex = target;
    controller.centeredIndex.value = target;
    controller.currentVisibleIndex.value = target;
    capturePendingCenteredEntry(preferredIndex: target);
  }

  void capturePendingCenteredEntry({int? preferredIndex, PostsModel? model}) {
    if (model != null) {
      final docId = model.docID.trim();
      controller._pendingCenteredDocId = docId.isEmpty ? null : docId;
      return;
    }
    final candidateIndex = preferredIndex ??
        (controller.currentVisibleIndex.value >= 0
            ? controller.currentVisibleIndex.value
            : controller.lastCenteredIndex);
    if (candidateIndex == null ||
        candidateIndex < 0 ||
        candidateIndex >= controller.all.length) {
      controller._pendingCenteredDocId = null;
      return;
    }
    final docId = controller.all[candidateIndex].docID.trim();
    controller._pendingCenteredDocId = docId.isEmpty ? null : docId;
  }
}
