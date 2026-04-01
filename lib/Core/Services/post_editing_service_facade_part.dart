part of 'post_editing_service.dart';

PostEditingService? maybeFindPostEditingService() =>
    Get.isRegistered<PostEditingService>()
        ? Get.find<PostEditingService>()
        : null;

PostEditingService ensurePostEditingService() =>
    maybeFindPostEditingService() ?? Get.put(PostEditingService());
