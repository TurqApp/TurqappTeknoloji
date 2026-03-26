part of 'current_user_service.dart';

CurrentUserService _currentUserServiceInstance() {
  CurrentUserService._instance ??= CurrentUserService._internal();
  return CurrentUserService._instance!;
}

CurrentUserService? _maybeFindCurrentUserService() {
  final isRegistered = Get.isRegistered<CurrentUserService>();
  if (!isRegistered) return null;
  return Get.find<CurrentUserService>();
}

CurrentUserService _ensureCurrentUserService({bool permanent = false}) {
  final existing = _maybeFindCurrentUserService();
  if (existing != null) return existing;
  return Get.put(CurrentUserService.instance, permanent: permanent);
}

void _handleCurrentUserServiceClose(CurrentUserService controller) {
  controller._disposeLifecycleResources();
}

void _handleCurrentUserLifecycleState(
  CurrentUserService controller,
  AppLifecycleState state,
) {
  controller._handleLifecycleStateChange(state);
}
