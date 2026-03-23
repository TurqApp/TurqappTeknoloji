part of 'editor_phone_number_controller.dart';

extension _EditorPhoneNumberControllerDataPart on EditorPhoneNumberController {
  void _seedFromCurrentUser() {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;
    final phone = currentUser.phoneNumber.trim();
    if (phone.isEmpty) return;
    phoneController.text = phone;
    phoneValue.value = phone;
  }

  Future<void> _loadInitialPhone() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final data = await _userRepository.getUserRaw(
      uid,
      preferCache: true,
      cacheOnly: true,
    );
    final rawPhone = (data ?? const {})["phoneNumber"]?.toString().trim() ?? "";
    if (rawPhone.isNotEmpty) {
      phoneController.text = rawPhone;
      phoneValue.value = rawPhone;
    }
  }

  Future<String> _resolveAccountEmail() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return "";

    final authEmail = normalizeEmailAddress(current.email);
    if (authEmail.isNotEmpty) return authEmail;

    final currentUserEmail =
        normalizeEmailAddress(_userService.currentUser?.email);
    if (currentUserEmail.isNotEmpty) return currentUserEmail;

    final data = await _userRepository.getUserRaw(current.uid);
    return normalizeEmailAddress(
      (((data ?? const {})["email"]) ?? "").toString(),
    );
  }
}
