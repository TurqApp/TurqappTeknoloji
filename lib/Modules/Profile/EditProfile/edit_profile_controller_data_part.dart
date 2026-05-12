part of 'edit_profile_controller.dart';

extension EditProfileControllerDataPart on EditProfileController {
  void _handleLifecycleInit() {
    fetchAndSetUserData();
    _bindUserContactData();
    // NSFW detector OptimizedNSFWService ile lazy initialize edilir
  }

  void _handleLifecycleClose() {
    _userSub?.cancel();
    firstNameController.dispose();
    lastNameController.dispose();
  }

  void _bindUserContactData() {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    _userSub?.cancel();
    _userSub = _userRepository.watchUserRaw(uid).listen((data) {
      if (data == null) return;
      final profile = (data["profile"] is Map)
          ? Map<String, dynamic>.from(data["profile"] as Map)
          : const <String, dynamic>{};
      final rawNickname = (data["nickname"] ??
              data["username"] ??
              data["userName"] ??
              data["displayName"] ??
              profile["nickname"] ??
              profile["username"] ??
              profile["displayName"] ??
              "")
          .toString()
          .trim();
      final rawAvatar = resolveAvatarUrl(data, profile: profile).trim();
      final rawEmail = (data["email"] ??
              profile["email"] ??
              CurrentUserService.instance.email ??
              "")
          .toString()
          .trim();
      final rawPhone = (data["phoneNumber"] ?? profile["phoneNumber"] ?? "")
          .toString()
          .trim();
      nickname.value = rawNickname;
      avatarUrl.value = rawAvatar;
      email.value = rawEmail;
      phoneNumber.value = rawPhone;
      if (kDebugMode) {
        debugPrint(
          '[EditProfileIdentity] source=users uid=$uid '
          'nicknameEmpty=${rawNickname.isEmpty} '
          'avatarEmpty=${rawAvatar.isEmpty} '
          'serviceNicknameEmpty=${CurrentUserService.instance.nickname.trim().isEmpty} '
          'serviceAvatarEmpty=${CurrentUserService.instance.avatarUrl.trim().isEmpty}',
        );
      }
    });
  }

  Future<void> _fetchAndSetUserDataImpl() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final currentUser = userService.currentUser;

    if (currentUser != null) {
      firstNameController.text = currentUser.firstName;
      lastNameController.text = currentUser.lastName;
      nickname.value = currentUser.nickname.trim();
      avatarUrl.value = currentUser.avatarUrl.trim();
      return;
    }

    final data = await _userRepository.getUserRaw(uid);
    if (data != null) {
      firstNameController.text = data["firstName"] ?? "";
      lastNameController.text = data["lastName"] ?? "";
      final profile = (data["profile"] is Map)
          ? Map<String, dynamic>.from(data["profile"] as Map)
          : const <String, dynamic>{};
      nickname.value = (data["nickname"] ??
              data["username"] ??
              data["userName"] ??
              data["displayName"] ??
              profile["nickname"] ??
              profile["username"] ??
              profile["displayName"] ??
              "")
          .toString()
          .trim();
      avatarUrl.value = resolveAvatarUrl(data, profile: profile).trim();
    }
  }
}
