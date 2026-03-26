part of 'editor_nickname_controller.dart';

class EditorNicknameController extends GetxController {
  static EditorNicknameController ensure({bool permanent = false}) =>
      _ensureEditorNicknameController(permanent: permanent);

  static EditorNicknameController? maybeFind() =>
      _maybeFindEditorNicknameController();

  final TextEditingController nicknameController = TextEditingController();

  final uid = CurrentUserService.instance.effectiveUserId;
  static const Duration _graceWindow = Duration(hours: 1);
  static const Duration _changeCooldown = Duration(days: 15);

  // Live kontrol durumu
  final RxBool isChecking = false.obs;
  final RxnBool isAvailable = RxnBool();
  final RxString statusText = ''.obs;
  final RxBool isCooldownActive = false.obs;
  final RxString cooldownText = ''.obs;
  String _originalNickname = '';
  final RxBool hasUserTyped = false.obs;
  Timer? _debounce;
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _handleEditorNicknameControllerInit(this);
  }

  @override
  void onClose() {
    _handleEditorNicknameControllerClose(this);
    super.onClose();
  }

  String get currentNormalized => _editorNicknameCurrentNormalized(this);

  bool get canSave => _editorNicknameCanSave(this);

  Future<void> setData() => _setDataImpl();
}
