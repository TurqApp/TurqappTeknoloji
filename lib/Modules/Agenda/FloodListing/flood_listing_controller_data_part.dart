part of 'flood_listing_controller.dart';

extension FloodListingControllerDataPart on FloodListingController {
  Future<void> getFloods(int floodCount, String anyFloodID) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    capturePendingCenteredEntry();
    floods.clear();
    _visibleFractions.clear();
    _playableRawIndices.clear();
    _playableQueueIndexByRawIndex.clear();
    _promotedSecondSegmentBatchStarts.clear();

    final baseID = anyFloodID.replaceFirst(RegExp(r'_\d+$'), '');
    final ids = List<String>.generate(floodCount, (i) => '${baseID}_$i');
    Map<String, PostsModel> fetched = <String, PostsModel>{};
    try {
      fetched = await _postRepository.fetchPostsByIds(
        ids,
        preferCache: true,
        cacheOnly: false,
      );
    } catch (_) {
      try {
        fetched = await _postRepository.fetchPostsByIds(
          ids,
          preferCache: true,
          cacheOnly: true,
        );
      } catch (_) {
        fetched = <String, PostsModel>{};
      }
      if (fetched.length < ids.length) {
        try {
          final fallbackCards = await _postRepository.fetchPostCardsByIds(
            ids,
            preferCache: true,
            cacheOnly: false,
          );
          if (fallbackCards.isNotEmpty) {
            fetched = <String, PostsModel>{
              ...fallbackCards,
              ...fetched,
            };
          }
        } catch (_) {}
      }
    }

    final rootID = '${baseID}_0';
    try {
      final rootModel = fetched[rootID];
      if (rootModel != null) {
        final m = rootModel;
        if (m.deletedPost != true && m.timeStamp <= nowMs) floods.add(m);
      }
    } catch (e) {
      print('🔥 Kök flood alınamadı: $e');
    }

    for (var i = 1; i < floodCount; i++) {
      final docID = '${baseID}_$i';
      try {
        final model = fetched[docID];
        if (model != null) {
          final m = model;
          if (m.deletedPost != true && m.timeStamp <= nowMs) floods.add(m);
        }
      } catch (e) {
        print('🔥 Flood verisi alınamadı: $e');
      }
    }
    resumeCenteredPost();
    _scheduleInitialFloodSegmentPriorityPlan();
  }
}
