import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';

import 'hls_segment_policy.dart';
import 'm3u8_parser.dart';

part 'hls_data_usage_probe_class_part.dart';
part 'hls_data_usage_probe_facade_part.dart';
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
