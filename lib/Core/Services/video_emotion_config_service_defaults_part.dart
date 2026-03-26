part of 'video_emotion_config_service.dart';

extension VideoRemoteConfigServiceDefaultsPart on VideoRemoteConfigService {
  int get defaultPrefetchBreadthCount => _defaultPrefetchBreadthCount;
  int get defaultPrefetchBreadthSegments => _defaultPrefetchBreadthSegments;
  int get defaultPrefetchDepthCount => _defaultPrefetchDepthCount;
  int get defaultPrefetchMaxConcurrent => _defaultPrefetchMaxConcurrent;
  int get defaultCacheSoftLimitMb => _defaultCacheSoftLimitMb;
  int get defaultCacheHardLimitMb => _defaultCacheHardLimitMb;
  int get defaultCacheRecentProtectCount => _defaultCacheRecentProtectCount;
}
