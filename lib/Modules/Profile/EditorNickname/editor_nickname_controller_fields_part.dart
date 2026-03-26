part of 'editor_nickname_controller.dart';

class _EditorNicknameControllerState {
  final TextEditingController nicknameController = TextEditingController();
  final String uid = CurrentUserService.instance.effectiveUserId;
  final RxBool isChecking = false.obs;
  final RxnBool isAvailable = RxnBool();
  final RxString statusText = ''.obs;
  final RxBool isCooldownActive = false.obs;
  final RxString cooldownText = ''.obs;
  String originalNickname = '';
  final RxBool hasUserTyped = false.obs;
  Timer? debounce;
  final UserRepository userRepository = UserRepository.ensure();
}

extension EditorNicknameControllerFieldsPart on EditorNicknameController {
  TextEditingController get nicknameController => _state.nicknameController;
  String get uid => _state.uid;
  RxBool get isChecking => _state.isChecking;
  RxnBool get isAvailable => _state.isAvailable;
  RxString get statusText => _state.statusText;
  RxBool get isCooldownActive => _state.isCooldownActive;
  RxString get cooldownText => _state.cooldownText;
  String get _originalNickname => _state.originalNickname;
  set _originalNickname(String value) => _state.originalNickname = value;
  RxBool get hasUserTyped => _state.hasUserTyped;
  Timer? get _debounce => _state.debounce;
  set _debounce(Timer? value) => _state.debounce = value;
  UserRepository get _userRepository => _state.userRepository;
}
