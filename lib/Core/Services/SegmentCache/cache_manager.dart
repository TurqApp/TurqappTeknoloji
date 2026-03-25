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

  late String _cacheDir;
  CacheIndex _index = CacheIndex();
  final CacheMetrics metrics = CacheMetrics();
  int? _userHardLimitBytes;
  int? _userSoftLimitBytes;

  Timer? _persistTimer;
  Timer? _reconcileTimer;
  bool _persistDirty = false;

  /// Per-key write lock — aynı segment için eş zamanlı yazımı engeller.
  final Map<String, Future<File>> _writeInFlight = {};

  /// Coalesced eviction — birden fazla writeSegment tek eviction tetikler.
  Future<void>? _evictionInFlight;

  /// Son N oynatılan video — eviction'da korunur.
  final List<String> _recentlyPlayed = [];
  final Map<String, double> _lastPersistedProgress = {};
  final Map<String, DateTime> _lastPersistedProgressAt = {};

  @override
  Future<void> onClose() async {
    await _handleSegmentCacheManagerOnClose();
    super.onClose();
  }
}
