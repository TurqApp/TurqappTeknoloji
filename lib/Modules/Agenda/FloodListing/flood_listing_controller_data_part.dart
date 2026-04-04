part of 'flood_listing_controller.dart';

extension FloodListingControllerDataPart on FloodListingController {
  Future<void> getFloods(int floodCount, String anyFloodID) async {
    capturePendingCenteredEntry();
    floods.clear();

    final baseID = anyFloodID.replaceFirst(RegExp(r'_\d+$'), '');
    final ids = List<String>.generate(floodCount, (i) => '${baseID}_$i');
    // Flood detail needs canonical post docs, not potentially stale search-card
    // projections. Otherwise migrated HLS fields can lag behind and the inline
    // player stays on the gray poster inside the flood route.
    final fetched = await _postRepository.fetchPostsByIds(
      ids,
      preferCache: false,
      cacheOnly: false,
    );

    final rootID = '${baseID}_0';
    try {
      final rootModel = fetched[rootID];
      if (rootModel != null) {
        final m = rootModel;
        if (m.deletedPost != true) floods.add(m);
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
          if (m.deletedPost != true) floods.add(m);
        }
      } catch (e) {
        print('🔥 Flood verisi alınamadı: $e');
      }
    }
    resumeCenteredPost();
    _scheduleFloodSegmentWarmup(
      preferredIndex: 0,
      readySegments: 2,
      windowCount: floods.length,
    );
  }
}
