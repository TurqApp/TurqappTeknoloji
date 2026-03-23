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
      final rawEmail = (data["email"] ??
              profile["email"] ??
              CurrentUserService.instance.email ??
              "")
          .toString()
          .trim();
      final rawPhone = (data["phoneNumber"] ?? profile["phoneNumber"] ?? "")
          .toString()
          .trim();
      email.value = rawEmail;
      phoneNumber.value = rawPhone;
    });
  }

  Future<void> _fetchAndSetUserDataImpl() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final currentUser = userService.currentUser;

    if (currentUser != null) {
      firstNameController.text = currentUser.firstName;
      lastNameController.text = currentUser.lastName;
      return;
    }

    final data = await _userRepository.getUserRaw(uid);
    if (data != null) {
      firstNameController.text = data["firstName"] ?? "";
      lastNameController.text = data["lastName"] ?? "";
    }
  }
}
