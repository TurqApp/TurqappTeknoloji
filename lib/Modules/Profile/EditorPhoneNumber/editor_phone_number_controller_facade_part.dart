part of 'editor_phone_number_controller.dart';

EditorPhoneNumberController ensureEditorPhoneNumberController({
  bool permanent = false,
}) {
  final existing = maybeFindEditorPhoneNumberController();
  if (existing != null) return existing;
  return Get.put(
    EditorPhoneNumberController(),
    permanent: permanent,
  );
}

EditorPhoneNumberController? maybeFindEditorPhoneNumberController() {
  final isRegistered = Get.isRegistered<EditorPhoneNumberController>();
  if (!isRegistered) return null;
  return Get.find<EditorPhoneNumberController>();
}

extension EditorPhoneNumberControllerFacadePart on EditorPhoneNumberController {
  Future<String> resolveAccountEmail() => _resolveEditorPhoneAccountEmail(this);

  bool get isPhoneValid => _isEditorPhoneValid(this);
}
