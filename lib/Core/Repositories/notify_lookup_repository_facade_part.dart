part of 'notify_lookup_repository_library.dart';

NotifyLookupRepository? maybeFindNotifyLookupRepository() =>
    Get.isRegistered<NotifyLookupRepository>()
        ? Get.find<NotifyLookupRepository>()
        : null;

NotifyLookupRepository ensureNotifyLookupRepository() =>
    maybeFindNotifyLookupRepository() ??
    Get.put(NotifyLookupRepository(), permanent: true);
