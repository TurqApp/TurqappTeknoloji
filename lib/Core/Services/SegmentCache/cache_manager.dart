import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/eviction_scoring_engine.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/video_emotion_config_service.dart';

import 'cache_metrics.dart';
import 'models.dart';

part 'cache_manager_eviction_part.dart';
part 'cache_manager_facade_part.dart';
part 'cache_manager_fields_part.dart';
part 'cache_manager_runtime_part.dart';
part 'cache_manager_storage_part.dart';
part 'cache_manager_write_part.dart';

/// Segment seviyesinde HLS disk cache yöneticisi.
/// CDN path'ini mirror ederek disk'e yazar, index.json ile takip eder.
///
/// Disk yapısı:
/// ```
/// {appSupport}/hls_cache/
///   index.json
///   Posts/{docID}/hls/master.m3u8
///   Posts/{docID}/hls/720p/playlist.m3u8
///   Posts/{docID}/hls/720p/segment_0.ts
/// ```
class SegmentCacheManager extends GetxController {
  static SegmentCacheManager? maybeFind() {
    final isRegistered = Get.isRegistered<SegmentCacheManager>();
    if (!isRegistered) return null;
    return Get.find<SegmentCacheManager>();
  }

  static SegmentCacheManager ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SegmentCacheManager(), permanent: true);
  }

  final _state = _SegmentCacheManagerState();

  @override
  Future<void> onClose() async {
    await _handleSegmentCacheManagerOnClose();
    super.onClose();
  }
}
