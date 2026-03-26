part of 'editor_phone_number_controller.dart';

class EditorPhoneNumberController extends GetxController {
  static EditorPhoneNumberController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      EditorPhoneNumberController(),
      permanent: permanent,
    );
  }

  static EditorPhoneNumberController? maybeFind() {
    final isRegistered = Get.isRegistered<EditorPhoneNumberController>();
    if (!isRegistered) return null;
    return Get.find<EditorPhoneNumberController>();
  }

  final _state = _EditorPhoneNumberControllerState();

  void _seedFromCurrentUser() => _seedEditorPhoneFromCurrentUser(this);

  Future<void> _loadInitialPhone() => _loadEditorPhoneInitial(this);

  Future<String> _resolveAccountEmail() =>
      _resolveEditorPhoneAccountEmail(this);

  @override
  void onInit() {
    super.onInit();
    _handleEditorPhoneOnInit(this);
  }

  @override
  void onClose() {
    _disposeEditorPhoneController(this);
    super.onClose();
  }

  bool get isPhoneValid => _isEditorPhoneValid(this);
}
