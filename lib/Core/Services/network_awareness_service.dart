import 'dart:async';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Utils/bool_utils.dart';
import 'media_compression_service.dart';
import 'SegmentCache/prefetch_scheduler.dart';

part 'network_awareness_service_policy_part.dart';
part 'network_awareness_service_class_part.dart';
part 'network_awareness_service_base_part.dart';
part 'network_awareness_service_facade_part.dart';
part 'network_awareness_service_fields_part.dart';
part 'network_awareness_service_models_part.dart';
part 'network_awareness_service_support_part.dart';
part 'network_awareness_service_storage_part.dart';

enum NetworkType {
  wifi('network_awareness.type_wifi'),
  cellular('network_awareness.type_cellular'),
  none('network_awareness.type_none');

  const NetworkType(this.labelKey);
  final String labelKey;
  String get label => labelKey.tr;
}

enum DataUsageMode {
  low('network_awareness.mode_low', 50),
  normal('network_awareness.mode_normal', 75),
  high('network_awareness.mode_high', 90);

  const DataUsageMode(this.labelKey, this.quality);
  final String labelKey;
  final int quality;
  String get label => labelKey.tr;
}
