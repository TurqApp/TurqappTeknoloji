part of 'top_tags_contoller_library.dart';

extension TopTagsControllerFeedPart on _TopTagsControllerBase {
  Future<void> fetchAgendaBigData({bool initial = false}) async {
    if (isLoadingMore || (!initial && !hasMore)) return;

    isLoadingMore = true;
    if (initial) {
      final currentCentered = centeredIndex.value;
      if (currentCentered >= 0 && currentCentered < agendaList.length) {
        _pendingCenteredDocId = agendaList[currentCentered].docID;
      } else if (lastCenteredIndex != null &&
          lastCenteredIndex! >= 0 &&
          lastCenteredIndex! < agendaList.length) {
        _pendingCenteredDocId = agendaList[lastCenteredIndex!].docID;
      }
    }

    try {
      final before = agendaList.length;
      final items = await _repo.fetchImagePostsPage(
        limit: 15,
        reset: initial,
      );
      agendaList.assignAll(items);
      _restoreCenteredPost();
      if (items.length == before) {
        hasMore = false;
      }
    } catch (e) {
      print('Firestore fetch error: $e');
    }

    isLoadingMore = false;
  }

  Future<void> getTags({bool forceRefresh = false}) async {
    try {
      final list = await _repo.fetchTrendingTags(
        resultLimit: 15,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      tags.assignAll(list);
    } catch (_) {}
  }
}
