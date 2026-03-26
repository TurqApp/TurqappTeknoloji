part of 'editor_email_controller_library.dart';

class _EditorEmailControllerState {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final RxInt countdown = 0.obs;
  final RxBool isCodeSent = false.obs;
  final RxBool isBusy = false.obs;
  final RxBool isEmailConfirmed = false.obs;
  Timer? timer;
  final UserRepository userRepository = UserRepository.ensure();
  final CurrentUserService userService = CurrentUserService.instance;
}

extension EditorEmailControllerFieldsPart on EditorEmailController {
  TextEditingController get emailController => _state.emailController;
  TextEditingController get codeController => _state.codeController;
  RxInt get countdown => _state.countdown;
  RxBool get isCodeSent => _state.isCodeSent;
  RxBool get isBusy => _state.isBusy;
  RxBool get isEmailConfirmed => _state.isEmailConfirmed;
  Timer? get _timer => _state.timer;
  set _timer(Timer? value) => _state.timer = value;
  UserRepository get _userRepository => _state.userRepository;
  CurrentUserService get _userService => _state.userService;
  String get _currentUid => _userService.effectiveUserId;
}
