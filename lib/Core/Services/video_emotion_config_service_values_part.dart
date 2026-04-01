part of 'video_emotion_config_service.dart';

extension VideoRemoteConfigServiceValuesPart on VideoRemoteConfigService {
  int get prefetchBreadthCount => _readInt(
        'video_prefetch_breadth_count',
        defaultPrefetchBreadthCount,
        1,
        20,
      );

  int get prefetchBreadthSegments => _readInt(
        'video_prefetch_breadth_segments',
        defaultPrefetchBreadthSegments,
        1,
        10,
      );

  int get prefetchDepthCount => _readInt('video_prefetch_depth_count',
      defaultPrefetchDepthCount, 1, 10);

  int get prefetchMaxConcurrent => _readInt(
        'video_prefetch_max_concurrent',
        defaultPrefetchMaxConcurrent,
        1,
        6,
      );

  int get cacheSoftLimitBytes =>
      _readInt('video_cache_soft_limit_mb',
          defaultCacheSoftLimitMb, 256, 10240) *
      1024 *
      1024;

  int get cacheHardLimitBytes =>
      _readInt('video_cache_hard_limit_mb',
          defaultCacheHardLimitMb, 512, 12288) *
      1024 *
      1024;

  int get cacheRecentProtectCount => _readInt(
        'video_cache_recent_protect_count',
        defaultCacheRecentProtectCount,
        1,
        20,
      );

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
