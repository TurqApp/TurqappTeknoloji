import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Runtime/app_root_navigation_service.dart';
import 'package:turqappv2/Core/Repositories/user_subdoc_repository.dart';
import 'package:turqappv2/Core/Services/mandatory_follow_service.dart';
import 'package:turqappv2/Core/Services/profile_manifest_sync_service.dart';
import 'package:turqappv2/Core/Services/user_document_schema.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Runtime/feature_runtime_services.dart';
import 'package:turqappv2/Runtime/primary_tab_router.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/phone_account_limiter.dart';

import 'sign_in_application_service.dart';
import 'sign_in_entry_warm_service.dart';
import 'sign_in_remote_service.dart';

part 'sign_in_controller_auth_part.dart';
part 'sign_in_controller_account_part.dart';
part 'sign_in_controller_lifecycle_part.dart';
part 'sign_in_controller_signup_part.dart';
part 'sign_in_controller_support_part.dart';

class _SignInTextControllers {
  final emailcontroller = TextEditingController(),
      passwordcontroller = TextEditingController(),
      nicknamecontroller = TextEditingController(),
      firstNameController = TextEditingController(),
      lastNameController = TextEditingController(),
      phoneNumberController = TextEditingController(),
      otpController = TextEditingController(),
      resetMailController = TextEditingController(),
      resetOtpController = TextEditingController(),
      newPasswordController = TextEditingController(),
      newPasswordRepeatController = TextEditingController();
}

class _SignInFocusNodes {
  final emailFocus = FocusNode().obs,
      passwordFocus = FocusNode().obs,
      nicknameFocus = FocusNode().obs,
      firstNameFocus = FocusNode().obs,
      lastNameFocus = FocusNode().obs,
      phoneNumberFocus = FocusNode().obs,
      otpFocus = FocusNode().obs,
      resetMailFocus = FocusNode().obs,
      resetOtpFocus = FocusNode().obs,
      newPasswordFocus = FocusNode().obs,
      newPasswordRepeatFocus = FocusNode().obs;
}

class _SignInStateFields {
  final selection = 0.obs;
  final typedBrandLength = 0.obs;
  final showBrandCursor = true.obs;
  final firstName = ''.obs,
      lastName = ''.obs,
      phoneNumber = ''.obs,
      otpCode = ''.obs,
      email = ''.obs,
      password = ''.obs,
      nickname = ''.obs,
      resetMail = ''.obs,
      resetOtp = ''.obs,
      newPassword = ''.obs,
      newPasswordRepeat = ''.obs;
  final nicknameAvilable = false.obs,
      emailAvilable = false.obs,
      passwordAvilable = false.obs,
      wait = false.obs,
      signupIdentityCheckLoading = false.obs,
      signupPoliciesAccepted = false.obs,
      showPassword = false.obs,
      showNewPassword = false.obs,
      showNewPasswordRepeat = false.obs,
      isFormValid = false.obs,
      resetPhoneNumber = ''.obs,
      resetOldPassword = ''.obs,
      resetUserID = ''.obs,
      signInEmail = ''.obs;
  final otpTimer = 0.obs;
  final signupCodeRequested = false.obs;
  final otpRequestInFlight = false.obs;
  final otpTimerReset = 0.obs;
  final resetCodeRequested = false.obs;
  final resetOtpRequestInFlight = false.obs;
  bool authEntryIsFirstLaunch = false;
  Timer? timer;
  Timer? emailAvailabilityDebounce;
  Timer? nicknameAvailabilityDebounce;
  Timer? typewriterTimer;
  Timer? cursorBlinkTimer;
  Timer? timerReset;
  Worker? selectionWorker;
  int emailAvailabilityRequestId = 0;
  int nicknameAvailabilityRequestId = 0;
  final Rxn<StoredAccount> selectedStoredAccount = Rxn<StoredAccount>();
}

mixin _SignInControllerBasePart on GetxController {
  final _controllers = _SignInTextControllers();
  final _focuses = _SignInFocusNodes();
  final _state = _SignInStateFields();

  @override
  void onInit() {
    super.onInit();
    _handleSignInControllerInit(this as SignInController);
  }

  @override
  void onClose() {
    _handleSignInControllerClose(this as SignInController);
    super.onClose();
  }
}

extension SignInControllerFieldsPart on SignInController {
  RxInt get selection => _state.selection;
  RxInt get typedBrandLength => _state.typedBrandLength;
  RxBool get showBrandCursor => _state.showBrandCursor;
  TextEditingController get emailcontroller => _controllers.emailcontroller;
  TextEditingController get passwordcontroller =>
      _controllers.passwordcontroller;
  TextEditingController get nicknamecontroller =>
      _controllers.nicknamecontroller;
  TextEditingController get firstNameController =>
      _controllers.firstNameController;
  TextEditingController get lastNameController =>
      _controllers.lastNameController;
  TextEditingController get phoneNumberController =>
      _controllers.phoneNumberController;
  TextEditingController get otpController => _controllers.otpController;
  TextEditingController get resetMailController =>
      _controllers.resetMailController;
  TextEditingController get resetOtpController =>
      _controllers.resetOtpController;
  TextEditingController get newPasswordController =>
      _controllers.newPasswordController;
  TextEditingController get newPasswordRepeatController =>
      _controllers.newPasswordRepeatController;

  Rx<FocusNode> get emailFocus => _focuses.emailFocus;
  Rx<FocusNode> get passwordFocus => _focuses.passwordFocus;
  Rx<FocusNode> get nicknameFocus => _focuses.nicknameFocus;
  Rx<FocusNode> get firstNameFocus => _focuses.firstNameFocus;
  Rx<FocusNode> get lastNameFocus => _focuses.lastNameFocus;
  Rx<FocusNode> get phoneNumberFocus => _focuses.phoneNumberFocus;
  Rx<FocusNode> get otpFocus => _focuses.otpFocus;
  Rx<FocusNode> get resetMailFocus => _focuses.resetMailFocus;
  Rx<FocusNode> get resetOtpFocus => _focuses.resetOtpFocus;
  Rx<FocusNode> get newPasswordFocus => _focuses.newPasswordFocus;
  Rx<FocusNode> get newPasswordRepeatFocus => _focuses.newPasswordRepeatFocus;

  RxString get firstName => _state.firstName;
  RxString get lastName => _state.lastName;
  RxString get phoneNumber => _state.phoneNumber;
  RxString get otpCode => _state.otpCode;
  RxString get email => _state.email;
  RxString get password => _state.password;
  RxString get nickname => _state.nickname;
  RxString get resetMail => _state.resetMail;
  RxString get resetOtp => _state.resetOtp;
  RxString get newPassword => _state.newPassword;
  RxString get newPasswordRepeat => _state.newPasswordRepeat;
  RxBool get nicknameAvilable => _state.nicknameAvilable;
  RxBool get emailAvilable => _state.emailAvilable;
  RxBool get passwordAvilable => _state.passwordAvilable;
  RxBool get wait => _state.wait;
  RxBool get signupIdentityCheckLoading => _state.signupIdentityCheckLoading;
  RxBool get signupPoliciesAccepted => _state.signupPoliciesAccepted;
  RxBool get showPassword => _state.showPassword;
  RxBool get showNewPassword => _state.showNewPassword;
  RxBool get showNewPasswordRepeat => _state.showNewPasswordRepeat;
  RxBool get isFormValid => _state.isFormValid;
  RxInt get otpTimer => _state.otpTimer;
  RxBool get signupCodeRequested => _state.signupCodeRequested;
  RxBool get otpRequestInFlight => _state.otpRequestInFlight;
  RxInt get otpTimerReset => _state.otpTimerReset;
  RxBool get resetCodeRequested => _state.resetCodeRequested;
  RxBool get resetOtpRequestInFlight => _state.resetOtpRequestInFlight;
  Timer? get _timer => _state.timer;
  set _timer(Timer? value) => _state.timer = value;
  Timer? get _emailAvailabilityDebounce => _state.emailAvailabilityDebounce;
  set _emailAvailabilityDebounce(Timer? value) =>
      _state.emailAvailabilityDebounce = value;
  Timer? get _nicknameAvailabilityDebounce =>
      _state.nicknameAvailabilityDebounce;
  set _nicknameAvailabilityDebounce(Timer? value) =>
      _state.nicknameAvailabilityDebounce = value;
  Timer? get _typewriterTimer => _state.typewriterTimer;
  set _typewriterTimer(Timer? value) => _state.typewriterTimer = value;
  Timer? get _cursorBlinkTimer => _state.cursorBlinkTimer;
  set _cursorBlinkTimer(Timer? value) => _state.cursorBlinkTimer = value;
  Timer? get _timerReset => _state.timerReset;
  set _timerReset(Timer? value) => _state.timerReset = value;
  Worker? get _selectionWorker => _state.selectionWorker;
  set _selectionWorker(Worker? value) => _state.selectionWorker = value;
  int get _emailAvailabilityRequestId => _state.emailAvailabilityRequestId;
  set _emailAvailabilityRequestId(int value) =>
      _state.emailAvailabilityRequestId = value;
  int get _nicknameAvailabilityRequestId =>
      _state.nicknameAvailabilityRequestId;
  set _nicknameAvailabilityRequestId(int value) =>
      _state.nicknameAvailabilityRequestId = value;
  Rxn<StoredAccount> get selectedStoredAccount => _state.selectedStoredAccount;
  RxString get resetPhoneNumber => _state.resetPhoneNumber;
  RxString get resetOldPassword => _state.resetOldPassword;
  RxString get resetUserID => _state.resetUserID;
  RxString get signInEmail => _state.signInEmail;
  bool get authEntryIsFirstLaunch => _state.authEntryIsFirstLaunch;
  set authEntryIsFirstLaunch(bool value) => _state.authEntryIsFirstLaunch = value;
}

class SignInController extends GetxController
    with GetSingleTickerProviderStateMixin, _SignInControllerBasePart {}

SignInController ensureSignInController({
  String? tag,
  bool permanent = false,
}) =>
    maybeFindSignInController(tag: tag) ??
    Get.put(SignInController(), tag: tag, permanent: permanent);

SignInController? maybeFindSignInController({String? tag}) =>
    Get.isRegistered<SignInController>(tag: tag)
        ? Get.find<SignInController>(tag: tag)
        : null;

void _handleSignInControllerInit(SignInController controller) {
  controller._handleLifecycleInit();
}

void _handleSignInControllerClose(SignInController controller) {
  controller._handleLifecycleClose();
}
