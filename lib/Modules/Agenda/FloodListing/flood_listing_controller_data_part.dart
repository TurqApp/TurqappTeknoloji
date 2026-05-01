part of 'flood_listing_controller.dart';

extension FloodListingControllerDataPart on FloodListingController {
  Future<List<PostsModel>> _loadFloodsFromManifest(String anyFloodID) async {
    return ExploreRepository.ensure().loadFloodManifestSeries(anyFloodID);
  }

  Future<void> getFloods(int floodCount, String anyFloodID) async {
    capturePendingCenteredEntry();
    floods.clear();
    _visibleFractions.clear();
    _playableRawIndices.clear();
    _playableQueueIndexByRawIndex.clear();
    _promotedSecondSegmentBatchStarts.clear();

    final manifestItems = await _loadFloodsFromManifest(anyFloodID);
    if (manifestItems.isNotEmpty) {
      debugPrint(
        '[FloodSeries] status=manifest_loaded root=$anyFloodID count=${manifestItems.length} first=${manifestItems.isEmpty ? '' : manifestItems.first.docID}',
      );
      floods.assignAll(manifestItems);
      resumeCenteredPost();
      _scheduleInitialFloodSegmentPriorityPlan();
      return;
    }
    debugPrint(
      '[FloodManifestStore] status=series_empty scope=detail root=$anyFloodID requestedCount=$floodCount',
    );
  }
}
