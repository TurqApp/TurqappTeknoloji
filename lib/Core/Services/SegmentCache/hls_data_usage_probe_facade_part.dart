part of 'hls_data_usage_probe.dart';

HlsDataUsageProbe? maybeFindHlsDataUsageProbe() {
  final isRegistered = Get.isRegistered<HlsDataUsageProbe>();
  if (!isRegistered) return null;
  return Get.find<HlsDataUsageProbe>();
}

HlsDataUsageProbe ensureHlsDataUsageProbe() {
  final existing = maybeFindHlsDataUsageProbe();
  if (existing != null) return existing;
  return Get.put(HlsDataUsageProbe(), permanent: true);
}

extension HlsDataUsageProbeFacadePart on HlsDataUsageProbe {
  String get sessionLabel => _label;
  HlsDebugNetworkProfile get networkProfile => _networkProfile;

  void resetSession({String label = 'default'}) {
    _events.clear();
    _segmentDownloads.clear();
    _segmentCacheHits.clear();
    _variantCatalogs.clear();
    _docUsage.clear();
    _inFlight.clear();
    _startedAt = DateTime.now();
    _label = label;
    _visibleDocId = null;
    _networkProfile = HlsDebugNetworkProfile.fast;
    _peakConcurrentDownloads = 0;
    _peakParallelDocDownloads = 0;
    _peakOffscreenParallelDownloads = 0;
    _variantSwitchesObserved = 0;
    _lastVisibleVariantKey = null;
  }

  void setVisibleDoc(String? docId) {
    _visibleDocId = docId;
  }

  void debugSetNetworkProfile(HlsDebugNetworkProfile profile) {
    _networkProfile = profile;
  }
}
