part of 'editor_phone_number_controller.dart';

void _seedEditorPhoneFromCurrentUser(EditorPhoneNumberController controller) {
  final currentUser = controller._userService.currentUser;
  if (currentUser == null) return;
  final phone = currentUser.phoneNumber.trim();
  if (phone.isEmpty) return;
  controller.phoneController.text = phone;
  controller.phoneValue.value = phone;
}

Future<void> _loadEditorPhoneInitial(
  EditorPhoneNumberController controller,
) async {
  final uid = controller._currentUid;
  if (uid.isEmpty) return;
  final data = await controller._userRepository.getUserRaw(
    uid,
    preferCache: true,
    cacheOnly: true,
  );
  final rawPhone = (data ?? const {})['phoneNumber']?.toString().trim() ?? '';
  if (rawPhone.isNotEmpty) {
    controller.phoneController.text = rawPhone;
    controller.phoneValue.value = rawPhone;
  }
}

Future<String> _resolveEditorPhoneAccountEmail(
  EditorPhoneNumberController controller,
) async {
  final current = FirebaseAuth.instance.currentUser;
  if (current == null) return '';

  final authEmail = normalizeEmailAddress(current.email);
  if (authEmail.isNotEmpty) return authEmail;

  final currentUserEmail = normalizeEmailAddress(
    controller._userService.currentUser?.email,
  );
  if (currentUserEmail.isNotEmpty) return currentUserEmail;

  final data = await controller._userRepository.getUserRaw(current.uid);
  return normalizeEmailAddress(
    (((data ?? const {})['email']) ?? '').toString(),
  );
}

void _handleEditorPhoneOnInit(EditorPhoneNumberController controller) {
  _seedEditorPhoneFromCurrentUser(controller);
  unawaited(_loadEditorPhoneInitial(controller));

  controller.phoneController.addListener(() {
    controller.phoneValue.value = controller.phoneController.text;
  });

  controller.codeController.addListener(() {
    controller.codeValue.value = controller.codeController.text;
  });
}

void _disposeEditorPhoneController(EditorPhoneNumberController controller) {
  controller._timer?.cancel();
  controller.phoneController.dispose();
  controller.codeController.dispose();
}

bool _isEditorPhoneValid(EditorPhoneNumberController controller) {
  final newPhone = phoneDigitsOnly(controller.phoneController.text.trim());
  return newPhone.length == 10 && newPhone.startsWith('5');
}
