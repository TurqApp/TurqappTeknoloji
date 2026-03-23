part of 'archives_controller.dart';

extension ArchiveControllerDataPart on ArchiveController {
  Future<void> _bootstrapArchive(String uid) async {
    final cached = await _profileRepository.readCachedArchive(uid);
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'archive:$uid',
        minInterval: ArchiveController._silentRefreshInterval,
      )) {
        unawaited(fetchData(silent: true));
      }
      return;
    }
    await fetchData();
  }

  Future<void> fetchData({bool silent = false}) async {
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
}
