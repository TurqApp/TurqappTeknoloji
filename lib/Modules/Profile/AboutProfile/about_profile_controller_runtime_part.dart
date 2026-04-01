part of 'about_profile_controller.dart';

Future<void> _loadAboutProfileUserData(
  AboutProfileController controller,
  String userID,
) async {
  final normalizedUserId = userID.trim();
  if (normalizedUserId.isEmpty) return;
  if (controller._loadedUserId == normalizedUserId &&
      controller._pendingLoad == null &&
      (controller.nickname.value.isNotEmpty ||
          controller.fullName.value.isNotEmpty ||
          controller.createdDate.value.isNotEmpty)) {
    return;
  }
  if (controller._pendingLoad != null &&
      controller._loadedUserId == normalizedUserId) {
    return controller._pendingLoad!;
  }

  controller._loadedUserId = normalizedUserId;
  controller._pendingLoad =
      _fetchAboutProfileUserData(controller, normalizedUserId);
  try {
    await controller._pendingLoad;
  } finally {
    controller._pendingLoad = null;
  }
}

Future<void> _fetchAboutProfileUserData(
  AboutProfileController controller,
  String userID,
) async {
  try {
    final currentUserId = controller._currentUid;
    if (currentUserId == userID && controller.userService.currentUser != null) {
      final user = controller.userService.currentUser!;
      controller.avatarUrl.value = user.avatarUrl;
      controller.nickname.value = user.nickname;
      controller.createdDate.value = user.createdDate;
      controller.fullName.value = user.fullName;
      return;
    }

    final summary = await controller._userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    if (summary != null) {
      controller.avatarUrl.value = summary.avatarUrl;
      controller.nickname.value = summary.nickname;
      controller.fullName.value = summary.displayName;
    }
    if (controller.createdDate.value.isNotEmpty &&
        controller.fullName.value.trim().isNotEmpty) {
      return;
    }
    final data = await controller._userRepository.getUserRaw(
      userID,
      preferCache: true,
      cacheOnly: true,
    );
    if (data == null) return;
    controller.createdDate.value =
        data.containsKey('createdDate') ? data['createdDate'] ?? '' : '';
    if (controller.fullName.value.trim().isEmpty) {
      controller.fullName.value =
          '${data["firstName"] ?? ""} ${data["lastName"] ?? ""}'.trim();
    }
  } catch (_) {}
}
