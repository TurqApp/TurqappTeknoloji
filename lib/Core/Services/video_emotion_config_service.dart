import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class VideoRemoteConfigService extends GetxService {
  static VideoRemoteConfigService? maybeFind() {
    if (!Get.isRegistered<VideoRemoteConfigService>()) return null;
    return Get.find<VideoRemoteConfigService>();
  }

  static VideoRemoteConfigService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(VideoRemoteConfigService(), permanent: true);
  }

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final RxBool _ready = false.obs;

  bool get isReady => _ready.value;

  static const int _defaultPrefetchBreadthCount = 5;
  static const int _defaultPrefetchBreadthSegments = 2;
  static const int _defaultPrefetchDepthCount = 3;
  static const int _defaultPrefetchMaxConcurrent = 2;
  static const int _defaultCacheSoftLimitMb = 2560;
  static const int _defaultCacheHardLimitMb = 3072;
  static const int _defaultCacheRecentProtectCount = 3;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 5)
              : const Duration(hours: 1),
        ),
      );

      await _remoteConfig.setDefaults({
        'video_prefetch_breadth_count': _defaultPrefetchBreadthCount,
        'video_prefetch_breadth_segments': _defaultPrefetchBreadthSegments,
        'video_prefetch_depth_count': _defaultPrefetchDepthCount,
        'video_prefetch_max_concurrent': _defaultPrefetchMaxConcurrent,
        'video_cache_soft_limit_mb': _defaultCacheSoftLimitMb,
        'video_cache_hard_limit_mb': _defaultCacheHardLimitMb,
        'video_cache_recent_protect_count': _defaultCacheRecentProtectCount,
      });

      await _remoteConfig.fetchAndActivate();
      _ready.value = true;
      debugPrint('[RemoteConfig] Video params activated');
    } catch (e) {
      _ready.value = true;
      debugPrint('[RemoteConfig] init failed, defaults used: $e');
    }
  }

  int get prefetchBreadthCount => _readInt(
      'video_prefetch_breadth_count', _defaultPrefetchBreadthCount, 1, 20);

  int get prefetchBreadthSegments => _readInt('video_prefetch_breadth_segments',
      _defaultPrefetchBreadthSegments, 1, 10);

  int get prefetchDepthCount =>
      _readInt('video_prefetch_depth_count', _defaultPrefetchDepthCount, 1, 10);

  int get prefetchMaxConcurrent => _readInt(
      'video_prefetch_max_concurrent', _defaultPrefetchMaxConcurrent, 1, 6);

  int get cacheSoftLimitBytes =>
      _readInt(
          'video_cache_soft_limit_mb', _defaultCacheSoftLimitMb, 256, 10240) *
      1024 *
      1024;

  int get cacheHardLimitBytes =>
      _readInt(
          'video_cache_hard_limit_mb', _defaultCacheHardLimitMb, 512, 12288) *
      1024 *
      1024;

  int get cacheRecentProtectCount => _readInt(
      'video_cache_recent_protect_count',
      _defaultCacheRecentProtectCount,
      1,
      20);

  int _readInt(String key, int fallback, int min, int max) {
    try {
      final value = _remoteConfig.getInt(key);
      if (value <= 0) return fallback;
      return value.clamp(min, max);
    } catch (_) {
      return fallback;
    }
  }
}
