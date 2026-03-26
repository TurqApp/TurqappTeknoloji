part of 'video_emotion_config_service.dart';

extension VideoRemoteConfigServiceDefaultsPart on VideoRemoteConfigService {
  int get defaultPrefetchBreadthCount =>
      VideoRemoteConfigService._defaultPrefetchBreadthCount;
  int get defaultPrefetchBreadthSegments =>
      VideoRemoteConfigService._defaultPrefetchBreadthSegments;
  int get defaultPrefetchDepthCount =>
      VideoRemoteConfigService._defaultPrefetchDepthCount;
  int get defaultPrefetchMaxConcurrent =>
      VideoRemoteConfigService._defaultPrefetchMaxConcurrent;
  int get defaultCacheSoftLimitMb =>
      VideoRemoteConfigService._defaultCacheSoftLimitMb;
  int get defaultCacheHardLimitMb =>
      VideoRemoteConfigService._defaultCacheHardLimitMb;
  int get defaultCacheRecentProtectCount =>
      VideoRemoteConfigService._defaultCacheRecentProtectCount;
}
