part of 'flood_listing_controller.dart';

extension FloodListingControllerDataPart on FloodListingController {
  Future<void> getFloods(int floodCount, String anyFloodID) async {
    capturePendingCenteredEntry();
    floods.clear();

    final baseID = anyFloodID.replaceFirst(RegExp(r'_\d+$'), '');
    final ids = List<String>.generate(floodCount, (i) => '${baseID}_$i');
    final fetched = await _postRepository.fetchPostCardsByIds(ids);

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
  }
}
