part of 'video_emotion_config_service.dart';

VideoRemoteConfigService? maybeFindVideoRemoteConfigService() =>
    Get.isRegistered<VideoRemoteConfigService>()
        ? Get.find<VideoRemoteConfigService>()
        : null;

VideoRemoteConfigService ensureVideoRemoteConfigService() =>
    maybeFindVideoRemoteConfigService() ??
    Get.put(VideoRemoteConfigService(), permanent: true);
