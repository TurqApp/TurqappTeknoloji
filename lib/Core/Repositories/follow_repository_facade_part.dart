part of 'follow_repository.dart';

FollowRepository? maybeFindFollowRepository() =>
    Get.isRegistered<FollowRepository>() ? Get.find<FollowRepository>() : null;

FollowRepository ensureFollowRepository() =>
    maybeFindFollowRepository() ?? Get.put(FollowRepository(), permanent: true);
