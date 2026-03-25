part of 'flood_listing_controller.dart';

extension FloodListingControllerRuntimePart on FloodListingController {
  void _handleOnInit() {
    scrollController.addListener(_onScroll);
  }

  void _handleOnClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
  }

  String floodInstanceTag(String docId) => 'flood_$docId';

  GlobalKey getFloodKey({required String docId}) {
    return _floodKeys.putIfAbsent(
      docId,
      () => GlobalObjectKey(floodInstanceTag(docId)),
    );
  }

  void _onScroll() {
    if (!scrollController.hasClients || floods.isEmpty) return;
    final position = scrollController.position;
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
        .clamp(0, floods.length - 1);
    if (centeredIndex.value != nextIndex) {
      if (lastCenteredIndex != null && lastCenteredIndex != nextIndex) {
        final prevModel = floods[lastCenteredIndex!];
        disposeAgendaContentController(prevModel.docID);
      }
      centeredIndex.value = nextIndex;
      currentVisibleIndex.value = nextIndex;
      lastCenteredIndex = nextIndex;
      capturePendingCenteredEntry(preferredIndex: nextIndex);
    }
  }

  void disposeAgendaContentController(String docID) {
    final tag = floodInstanceTag(docID);
    if (AgendaContentController.maybeFind(tag: tag) != null) {
      Get.delete<AgendaContentController>(tag: tag, force: true);
      print("🎯 Disposed AgendaContentController");
    }
  }

  int resolveResumeCenteredIndex() {
    if (floods.isEmpty) return -1;
    final pendingDocId = _pendingCenteredDocId;
    if (pendingDocId != null && pendingDocId.isNotEmpty) {
      final mapped = floods.indexWhere((post) => post.docID == pendingDocId);
      if (mapped >= 0) return mapped;
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < floods.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < floods.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  void resumeCenteredPost() {
    final target = resolveResumeCenteredIndex();
    if (target < 0 || target >= floods.length) return;
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
        candidateIndex >= floods.length) {
      _pendingCenteredDocId = null;
      return;
    }
    final docId = floods[candidateIndex].docID.trim();
    _pendingCenteredDocId = docId.isEmpty ? null : docId;
  }
}
