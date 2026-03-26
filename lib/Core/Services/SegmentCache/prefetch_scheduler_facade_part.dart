part of 'prefetch_scheduler.dart';

PrefetchScheduler? maybeFindPrefetchScheduler() {
  final isRegistered = Get.isRegistered<PrefetchScheduler>();
  if (!isRegistered) return null;
  return Get.find<PrefetchScheduler>();
}

PrefetchScheduler ensurePrefetchScheduler({bool permanent = false}) {
  final existing = maybeFindPrefetchScheduler();
  if (existing != null) return existing;
  return Get.put(PrefetchScheduler(), permanent: permanent);
}
