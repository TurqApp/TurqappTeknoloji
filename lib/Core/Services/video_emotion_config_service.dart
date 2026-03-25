import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

part 'video_emotion_config_service_values_part.dart';

class VideoRemoteConfigService extends GetxService {
  static VideoRemoteConfigService? maybeFind() {
    final isRegistered = Get.isRegistered<VideoRemoteConfigService>();
    if (!isRegistered) return null;
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
}
