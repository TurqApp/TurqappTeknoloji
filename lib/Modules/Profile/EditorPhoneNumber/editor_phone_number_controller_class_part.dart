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

  final phoneController = TextEditingController();
  final codeController = TextEditingController();

  final phoneValue = "".obs;
  final codeValue = "".obs;
  final countdown = 0.obs;
  final isCodeSent = false.obs;
  final isBusy = false.obs;
  final UserRepository _userRepository = UserRepository.ensure();
  final CurrentUserService _userService = CurrentUserService.instance;

  String get _currentUid => _userService.effectiveUserId;

  Timer? _timer;

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
