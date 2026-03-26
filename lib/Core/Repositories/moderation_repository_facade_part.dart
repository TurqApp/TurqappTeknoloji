part of 'moderation_repository.dart';

ModerationRepository? maybeFindModerationRepository() {
  final isRegistered = Get.isRegistered<ModerationRepository>();
  if (!isRegistered) return null;
  return Get.find<ModerationRepository>();
}

ModerationRepository ensureModerationRepository() {
  final existing = maybeFindModerationRepository();
  if (existing != null) return existing;
  return Get.put(ModerationRepository(), permanent: true);
}
