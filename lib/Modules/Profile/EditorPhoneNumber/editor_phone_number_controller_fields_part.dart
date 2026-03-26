part of 'editor_phone_number_controller.dart';

class _EditorPhoneNumberControllerState {
  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final phoneValue = ''.obs;
  final codeValue = ''.obs;
  final countdown = 0.obs;
  final isCodeSent = false.obs;
  final isBusy = false.obs;
  final UserRepository userRepository = UserRepository.ensure();
  final CurrentUserService userService = CurrentUserService.instance;
  Timer? timer;
}

extension EditorPhoneNumberControllerFieldsPart on EditorPhoneNumberController {
  TextEditingController get phoneController => _state.phoneController;
  TextEditingController get codeController => _state.codeController;
  RxString get phoneValue => _state.phoneValue;
  RxString get codeValue => _state.codeValue;
  RxInt get countdown => _state.countdown;
  RxBool get isCodeSent => _state.isCodeSent;
  RxBool get isBusy => _state.isBusy;
  UserRepository get _userRepository => _state.userRepository;
  CurrentUserService get _userService => _state.userService;
  String get _currentUid => _userService.effectiveUserId;
  Timer? get _timer => _state.timer;
  set _timer(Timer? value) => _state.timer = value;
}
