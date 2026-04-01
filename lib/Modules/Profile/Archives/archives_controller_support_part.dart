part of 'archives_controller.dart';

extension ArchiveControllerSupportPart on ArchiveController {
  String agendaInstanceTag(String docId) => 'archives_$docId';

  GlobalKey getAgendaKey({required String docId}) {
    return _agendaKeys.putIfAbsent(
      docId,
      () => GlobalObjectKey(agendaInstanceTag(docId)),
    );
  }

  void disposeAgendaContentController(String docID) {
    final tag = agendaInstanceTag(docID);
    if (AgendaContentController.maybeFind(tag: tag) != null) {
      Get.delete<AgendaContentController>(tag: tag, force: true);
    }
  }

  void removeArchivedPost(String docId) {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) return;
    final removedIndex = list.indexWhere(
      (post) => post.docID.trim() == normalizedDocId,
    );
    if (removedIndex < 0) return;

    disposeAgendaContentController(normalizedDocId);
    list.removeAt(removedIndex);

    if (list.isEmpty) {
      centeredIndex.value = -1;
      currentVisibleIndex.value = -1;
      lastCenteredIndex = null;
      _pendingCenteredDocId = null;
      return;
    }

    final nextIndex = removedIndex.clamp(0, list.length - 1);
    centeredIndex.value = nextIndex;
    currentVisibleIndex.value = nextIndex;
    lastCenteredIndex = nextIndex;
    capturePendingCenteredEntry(preferredIndex: nextIndex);
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
