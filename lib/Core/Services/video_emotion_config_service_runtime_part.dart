part of 'video_emotion_config_service.dart';

extension VideoRemoteConfigServiceRuntimePart on VideoRemoteConfigService {
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
        'video_prefetch_breadth_count':
            VideoRemoteConfigService._defaultPrefetchBreadthCount,
        'video_prefetch_breadth_segments':
            VideoRemoteConfigService._defaultPrefetchBreadthSegments,
        'video_prefetch_depth_count':
            VideoRemoteConfigService._defaultPrefetchDepthCount,
        'video_prefetch_max_concurrent':
            VideoRemoteConfigService._defaultPrefetchMaxConcurrent,
        'video_cache_soft_limit_mb':
            VideoRemoteConfigService._defaultCacheSoftLimitMb,
        'video_cache_hard_limit_mb':
            VideoRemoteConfigService._defaultCacheHardLimitMb,
        'video_cache_recent_protect_count':
            VideoRemoteConfigService._defaultCacheRecentProtectCount,
      });

      await _remoteConfig.fetchAndActivate();
      _ready.value = true;
      debugPrint('[RemoteConfig] Video params activated');
    } catch (e) {
      _ready.value = true;
      debugPrint('[RemoteConfig] init failed, defaults used: $e');
    }
  }
}
