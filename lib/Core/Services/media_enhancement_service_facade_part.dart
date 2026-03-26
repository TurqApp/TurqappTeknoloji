part of 'media_enhancement_service.dart';

MediaEnhancementService ensureMediaEnhancementService() {
  final existing = maybeFindMediaEnhancementService();
  if (existing != null) return existing;
  return Get.put(MediaEnhancementService());
}

MediaEnhancementService? maybeFindMediaEnhancementService() {
  final isRegistered = Get.isRegistered<MediaEnhancementService>();
  if (!isRegistered) return null;
  return Get.find<MediaEnhancementService>();
}
