part of 'notify_lookup_repository.dart';

NotifyLookupRepository? maybeFindNotifyLookupRepository() {
  final isRegistered = Get.isRegistered<NotifyLookupRepository>();
  if (!isRegistered) return null;
  return Get.find<NotifyLookupRepository>();
}

NotifyLookupRepository ensureNotifyLookupRepository() {
  final existing = maybeFindNotifyLookupRepository();
  if (existing != null) return existing;
  return Get.put(NotifyLookupRepository(), permanent: true);
}
