import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'm3u8_parser.dart';

part 'hls_data_usage_probe_record_part.dart';
part 'hls_data_usage_probe_snapshot_part.dart';
part 'hls_data_usage_probe_models_part.dart';

enum HlsTrafficSource {
  playback,
  prefetch,
}

enum HlsDebugNetworkProfile {
  fast,
  slow,
  unstable,
}

class HlsDataUsageProbe extends GetxController {
  static HlsDataUsageProbe? maybeFind() {
    final isRegistered = Get.isRegistered<HlsDataUsageProbe>();
    if (!isRegistered) return null;
    return Get.find<HlsDataUsageProbe>();
  }

  static HlsDataUsageProbe ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(HlsDataUsageProbe(), permanent: true);
  }

  final List<HlsTransferEvent> _events = <HlsTransferEvent>[];
  final Map<String, int> _segmentDownloads = <String, int>{};
  final Map<String, int> _segmentCacheHits = <String, int>{};
  final Map<String, _VariantCatalog> _variantCatalogs =
      <String, _VariantCatalog>{};
  final Map<String, _DocAccumulator> _docUsage = <String, _DocAccumulator>{};
  final Map<String, _InFlightTransfer> _inFlight =
      <String, _InFlightTransfer>{};
  final math.Random _random = math.Random(7);

  DateTime _startedAt = DateTime.now();
  String _label = 'default';
  String? _visibleDocId;
  HlsDebugNetworkProfile _networkProfile = HlsDebugNetworkProfile.fast;
  int _peakConcurrentDownloads = 0;
  int _peakParallelDocDownloads = 0;
  int _peakOffscreenParallelDownloads = 0;
  int _variantSwitchesObserved = 0;
  String? _lastVisibleVariantKey;

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
