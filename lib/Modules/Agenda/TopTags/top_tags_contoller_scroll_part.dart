part of 'top_tags_contoller_library.dart';

extension TopTagsControllerScrollPart on TopTagsController {
  int _resolveRestoreIndex() {
    if (agendaList.isEmpty) return -1;
    final pendingDocId = _pendingCenteredDocId;
    if (pendingDocId != null && pendingDocId.isNotEmpty) {
      final mapped =
          agendaList.indexWhere((post) => post.docID == pendingDocId);
      if (mapped >= 0) return mapped;
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < agendaList.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < agendaList.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  void _restoreCenteredPost() {
    final target = _resolveRestoreIndex();
    if (target < 0 || target >= agendaList.length) return;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    lastCenteredIndex = target;
    _pendingCenteredDocId = null;
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
        candidateIndex >= agendaList.length) {
      _pendingCenteredDocId = null;
      return;
    }
    final docId = agendaList[candidateIndex].docID.trim();
    _pendingCenteredDocId = docId.isEmpty ? null : docId;
  }

  void resumeCenteredPost() {
    _restoreCenteredPost();
  }

  void _onScroll() {
    final currentOffset = scrollController.offset;

    if (currentOffset > 1000) {
      navbar.showBar.value = currentOffset < _lastOffset;
    } else {
      navbar.showBar.value = true;
    }
    _lastOffset = currentOffset;

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      fetchAgendaBigData();
    }

    const itemHeight = 500.0;
    final newIndex =
        ((scrollController.offset + Get.height / 2) ~/ itemHeight) - 1;

    if (newIndex != currentVisibleIndex.value &&
        newIndex >= 0 &&
        newIndex < agendaList.length) {
      if (lastCenteredIndex != null && lastCenteredIndex != newIndex) {
        final prevModel = agendaList[lastCenteredIndex!];
        disposeAgendaContentController(prevModel.docID);
      }
      currentVisibleIndex.value = newIndex;
      centeredIndex.value = newIndex;
      lastCenteredIndex = newIndex;
      capturePendingCenteredEntry(preferredIndex: newIndex);
    }
  }

  void updateVisibleIndexByPosition(
    ScrollMetrics metrics,
    BuildContext context,
  ) {
    if (agendaList.isEmpty) return;
    if (metrics.pixels <= 0) {
      centeredIndex.value = 0;
      currentVisibleIndex.value = 0;
      lastCenteredIndex = 0;
      capturePendingCenteredEntry(preferredIndex: 0);
      return;
    }
    final estimatedItemExtent = (metrics.viewportDimension * 0.74).clamp(
      320.0,
      680.0,
    );
    final nextIndex = (((metrics.pixels + metrics.viewportDimension * 0.25) /
                estimatedItemExtent)
            .floor())
        .clamp(0, agendaList.length - 1);
    centeredIndex.value = nextIndex;
    currentVisibleIndex.value = nextIndex;
    lastCenteredIndex = nextIndex;
    capturePendingCenteredEntry(preferredIndex: nextIndex);
  }

  void disposeAgendaContentController(String docID) {
    final tag = agendaInstanceTag(docID);
    if (AgendaContentController.maybeFind(tag: tag) != null) {
      Get.delete<AgendaContentController>(tag: tag, force: true);
      print('Disposed AgendaContentController');
    }
  }
}
