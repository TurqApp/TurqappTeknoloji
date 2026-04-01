part of 'media_enhancement_service.dart';

MediaEnhancementService ensureMediaEnhancementService() =>
    maybeFindMediaEnhancementService() ?? Get.put(MediaEnhancementService());

MediaEnhancementService? maybeFindMediaEnhancementService() =>
    Get.isRegistered<MediaEnhancementService>()
        ? Get.find<MediaEnhancementService>()
        : null;
