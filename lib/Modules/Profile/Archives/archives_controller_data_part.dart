part of 'archives_controller.dart';

extension _ArchiveControllerDataPart on ArchiveController {
  Future<void> _bootstrapArchive(String uid) async {
    final cached = await _profileRepository.readCachedArchive(uid);
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'archive:$uid',
        minInterval: _archiveControllerSilentRefreshInterval,
      )) {
        unawaited(fetchArchiveData(silent: true));
      }
      return;
    }
    await fetchArchiveData();
  }

  Future<void> fetchArchiveData({bool silent = false}) async {
    final uid = _resolvedCurrentUid;
    if (uid.isEmpty) return;
    if (!silent) {
      isLoading.value = true;
    }
    final currentCentered = centeredIndex.value;
    if (currentCentered >= 0 && currentCentered < list.length) {
      _pendingCenteredDocId = list[currentCentered].docID;
    } else if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < list.length) {
      _pendingCenteredDocId = list[lastCenteredIndex!].docID;
    }
    try {
      final posts = await _profileRepository.fetchArchive(uid);
      list.assignAll(posts);
      _restoreCenteredPost();
      SilentRefreshGate.markRefreshed('archive:$uid');
    } finally {
      isLoading.value = false;
    }
  }

  int _resolveRestoreIndex() {
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

  void _restoreCenteredPost() {
    final target = _resolveRestoreIndex();
    if (target < 0 || target >= list.length) return;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    lastCenteredIndex = target;
    _pendingCenteredDocId = null;
  }
}
