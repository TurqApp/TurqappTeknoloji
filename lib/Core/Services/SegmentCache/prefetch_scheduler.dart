import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_policy_engine.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/prefetch_scoring_engine.dart';
import 'package:turqappv2/Core/Services/video_telemetry_service.dart';
import 'package:turqappv2/Core/Services/video_emotion_config_service.dart';

import '../network_awareness_service.dart';
import 'cache_manager.dart';
import 'download_worker.dart';
import 'hls_data_usage_probe.dart';
import 'm3u8_parser.dart';
import 'network_policy.dart';

part 'prefetch_scheduler_class_part.dart';
part 'prefetch_scheduler_facade_part.dart';
part 'prefetch_scheduler_queue_part.dart';
part 'prefetch_scheduler_worker_part.dart';
part 'prefetch_scheduler_runtime_part.dart';
part 'prefetch_scheduler_models_part.dart';
part 'prefetch_scheduler_fields_part.dart';
part 'prefetch_scheduler_config_part.dart';
