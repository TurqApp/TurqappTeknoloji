part of 'prefetch_scheduler.dart';

PrefetchScheduler? maybeFindPrefetchScheduler() =>
    Get.isRegistered<PrefetchScheduler>()
        ? Get.find<PrefetchScheduler>()
        : null;

PrefetchScheduler ensurePrefetchScheduler({bool permanent = false}) =>
    maybeFindPrefetchScheduler() ??
    Get.put(PrefetchScheduler(), permanent: permanent);
