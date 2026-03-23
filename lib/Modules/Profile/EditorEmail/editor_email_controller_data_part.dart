part of 'editor_email_controller.dart';

extension _EditorEmailControllerDataPart on EditorEmailController {
  void _seedFromCurrentSources() {
    final authUser = FirebaseAuth.instance.currentUser;
    final currentUser = _userService.currentUser;
    final seededEmail = currentUser?.email.trim().isNotEmpty == true
        ? currentUser!.email.trim()
        : (authUser?.email ?? '').trim();
    if (seededEmail.isNotEmpty) {
      emailController.text = seededEmail;
    }
    isEmailConfirmed.value = (currentUser?.email.isNotEmpty == true &&
            _userService.emailVerifiedRx.value) ||
        authUser?.emailVerified == true;
  }

  Future<void> fetchAndSetUserData() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final data = await _userRepository.getUserRaw(
      uid,
      preferCache: true,
      cacheOnly: true,
    );
    if (data != null) {
      final rawEmail = data["email"]?.toString().trim() ?? "";
      if (rawEmail.isNotEmpty) {
        emailController.text = rawEmail;
      }
      final firestoreVerified = data["emailVerified"] == true;
      final authVerified =
          FirebaseAuth.instance.currentUser?.emailVerified == true;
      isEmailConfirmed.value = firestoreVerified || authVerified;
    }
  }
}
