part of 'about_profile_controller.dart';

extension AboutProfileControllerDataPart on AboutProfileController {
  Future<void> getUserData(String userID) async {
    final normalizedUserId = userID.trim();
    if (normalizedUserId.isEmpty) return;
    if (_loadedUserId == normalizedUserId &&
        _pendingLoad == null &&
        (nickname.value.isNotEmpty ||
            fullName.value.isNotEmpty ||
            createdDate.value.isNotEmpty)) {
      return;
    }
    if (_pendingLoad != null && _loadedUserId == normalizedUserId) {
      return _pendingLoad!;
    }

    _loadedUserId = normalizedUserId;
    _pendingLoad = _loadUserData(normalizedUserId);
    try {
      await _pendingLoad;
    } finally {
      _pendingLoad = null;
    }
  }

  Future<void> _loadUserData(String userID) async {
    try {
      final currentUserId = _currentUid;
      if (currentUserId == userID && userService.currentUser != null) {
        final user = userService.currentUser!;
        avatarUrl.value = user.avatarUrl;
        nickname.value = user.nickname;
        createdDate.value = user.createdDate;
        fullName.value = user.fullName;
        return;
      }

      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary != null) {
        avatarUrl.value = summary.avatarUrl;
        nickname.value = summary.nickname;
        fullName.value = summary.displayName;
      }
      if (createdDate.value.isNotEmpty && fullName.value.trim().isNotEmpty) {
        return;
      }
      final data = await _userRepository.getUserRaw(
        userID,
        preferCache: true,
        cacheOnly: true,
      );
      if (data == null) return;
      createdDate.value =
          data.containsKey("createdDate") ? data["createdDate"] ?? "" : "";
      if (fullName.value.trim().isEmpty) {
        fullName.value =
            "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}".trim();
      }
    } catch (_) {}
  }
}
