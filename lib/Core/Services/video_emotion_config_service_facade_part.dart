part of 'video_emotion_config_service.dart';

VideoRemoteConfigService? maybeFindVideoRemoteConfigService() {
  final isRegistered = Get.isRegistered<VideoRemoteConfigService>();
  if (!isRegistered) return null;
  return Get.find<VideoRemoteConfigService>();
}

VideoRemoteConfigService ensureVideoRemoteConfigService() {
  final existing = maybeFindVideoRemoteConfigService();
  if (existing != null) return existing;
  return Get.put(VideoRemoteConfigService(), permanent: true);
}
