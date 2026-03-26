import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

part 'video_emotion_config_service_values_part.dart';
part 'video_emotion_config_service_defaults_part.dart';
part 'video_emotion_config_service_runtime_part.dart';
part 'video_emotion_config_service_facade_part.dart';

class VideoRemoteConfigService extends GetxService {
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
}
