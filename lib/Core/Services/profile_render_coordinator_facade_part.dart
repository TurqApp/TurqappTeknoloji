part of 'profile_render_coordinator.dart';

ProfileRenderCoordinator? _maybeFindProfileRenderCoordinator() {
  final isRegistered = Get.isRegistered<ProfileRenderCoordinator>();
  if (!isRegistered) return null;
  return Get.find<ProfileRenderCoordinator>();
}

ProfileRenderCoordinator _ensureProfileRenderCoordinator() {
  final existing = _maybeFindProfileRenderCoordinator();
  if (existing != null) return existing;
  return Get.put(ProfileRenderCoordinator(), permanent: true);
}
