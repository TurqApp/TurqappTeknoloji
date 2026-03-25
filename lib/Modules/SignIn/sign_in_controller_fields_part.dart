part of 'sign_in_controller.dart';

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
  final Rxn<StoredAccount> selectedStoredAccount = Rxn<StoredAccount>();
}

extension SignInControllerFieldsPart on SignInController {
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
  Rxn<StoredAccount> get selectedStoredAccount => _state.selectedStoredAccount;
  RxString get resetPhoneNumber => _state.resetPhoneNumber;
  RxString get resetOldPassword => _state.resetOldPassword;
  RxString get resetUserID => _state.resetUserID;
  RxString get signInEmail => _state.signInEmail;
}
