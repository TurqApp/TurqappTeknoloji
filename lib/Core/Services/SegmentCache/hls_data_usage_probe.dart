import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'm3u8_parser.dart';

part 'hls_data_usage_probe_record_part.dart';
part 'hls_data_usage_probe_snapshot_part.dart';
part 'hls_data_usage_probe_models_part.dart';
part 'hls_data_usage_probe_fields_part.dart';

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

  final _state = _HlsDataUsageProbeState();

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
