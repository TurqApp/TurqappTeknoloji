import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subdoc_repository.dart';
import 'package:turqappv2/Core/Services/mandatory_follow_service.dart';
import 'package:turqappv2/Core/Services/user_document_schema.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Modules/Agenda/Common/post_content_controller.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Modules/Splash/splash_view.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/phone_account_limiter.dart';

part 'sign_in_controller_auth_part.dart';
part 'sign_in_controller_signup_part.dart';

class SignInController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSubdocRepository _userSubdocRepository =
      UserSubdocRepository.ensure();
  late AnimationController animationController;

  var selection = 0.obs;

  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController nicknamecontroller = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController resetMailController = TextEditingController();
  TextEditingController resetOtpController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController newPasswordRepeatController = TextEditingController();

  Rx<FocusNode> emailFocus = FocusNode().obs;
  Rx<FocusNode> passwordFocus = FocusNode().obs;
  Rx<FocusNode> nicknameFocus = FocusNode().obs;
  Rx<FocusNode> firstNameFocus = FocusNode().obs;
  Rx<FocusNode> lastNameFocus = FocusNode().obs;
  Rx<FocusNode> phoneNumberFocus = FocusNode().obs;
  Rx<FocusNode> otpFocus = FocusNode().obs;
  Rx<FocusNode> resetMailFocus = FocusNode().obs;
  Rx<FocusNode> resetOtpFocus = FocusNode().obs;
  Rx<FocusNode> newPasswordFocus = FocusNode().obs;
  Rx<FocusNode> newPasswordRepeatFocus = FocusNode().obs;

  var firstName = ''.obs;
  var lastName = ''.obs;
  var phoneNumber = ''.obs;
  var otpCode = ''.obs;
  var email = ''.obs;
  var password = ''.obs;
  var nicknameAvilable = false.obs;
  var nickname = ''.obs;
  var resetMail = ''.obs;
  var resetOtp = ''.obs;
  var newPassword = "".obs;
  var newPasswordRepeat = "".obs;
  var emailAvilable = false.obs;
  var passwordAvilable = false.obs;
  var wait = false.obs;
  var signupIdentityCheckLoading = false.obs;
  var showPassword = false.obs;
  var showNewPassword = false.obs;
  var showNewPasswordRepeat = false.obs;

  var isFormValid = false.obs;

  var otpTimer = 0.obs;
  Timer? _timer;
  Timer? _emailAvailabilityDebounce;
  Timer? _nicknameAvailabilityDebounce;
  var signupCodeRequested = false.obs;
  var otpRequestInFlight = false.obs;

  var resetPhoneNumber = "".obs;
  var resetOldPassword = "".obs;
  var resetUserID = "".obs;
  var otpTimerReset = 0.obs;
  Timer? _timerReset;
  var resetCodeRequested = false.obs;
  var resetOtpRequestInFlight = false.obs;

  var signInEmail = "".obs;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west3');
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  int _emailAvailabilityRequestId = 0;
  int _nicknameAvailabilityRequestId = 0;
  static const String _signupAvailabilityUrl =
      'https://europe-west3-turqappteknoloji.cloudfunctions.net/checkSignupAvailabilityHttp';

  void _logSignupOtp(String stage, [Map<String, Object?> details = const {}]) {
    debugPrint('[SignupOtp] $stage ${details.isEmpty ? "" : details}');
  }

  void _ensureFeedTabSelected() {
    if (Get.isRegistered<NavBarController>()) {
      Get.find<NavBarController>().selectedIndex.value = 0;
      return;
    }
    final nav = Get.put(NavBarController());
    nav.selectedIndex.value = 0;
  }

  String _formatSeconds(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final m = (safe ~/ 60).toString().padLeft(2, '0');
    final s = (safe % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _clearSessionCachesAfterAccountSwitch() async {
    try {
      if (Get.isRegistered<UserProfileCacheService>()) {
        await Get.find<UserProfileCacheService>().clearAll();
      }
      PostContentController.clearUserProfileCache();
      if (Get.isRegistered<StoryRowController>()) {
        await Get.find<StoryRowController>().clearSessionCache();
      }
      if (Get.isRegistered<AgendaController>()) {
        final agenda = Get.find<AgendaController>();
        agenda.agendaList.clear();
        await agenda.refreshAgenda();
      }
    } catch (_) {}
  }

  Future<void> _restoreAccountIfPendingDeletion() async {
    await CurrentUserService.instance
        .restorePendingDeletionIfNeededForCurrentUser();
  }

  @override
  void onInit() {
    super.onInit();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    emailFocus.value.addListener(() => emailFocus.refresh());
    passwordFocus.value.addListener(() => passwordFocus.refresh());
    nicknameFocus.value.addListener(() => nicknameFocus.refresh());
    firstNameFocus.value.addListener(() => firstNameFocus.refresh());
    lastNameFocus.value.addListener(() => lastNameFocus.refresh());
    phoneNumberFocus.value.addListener(() => phoneNumberFocus.refresh());
    resetMailFocus.value.addListener(() => resetMailFocus.refresh());
    otpFocus.value.addListener(() => otpFocus.refresh());
    resetOtpFocus.value.addListener(() => otpFocus.refresh());
    newPasswordFocus.value.addListener(() => newPasswordFocus.refresh());
    newPasswordRepeatFocus.value.addListener(
      () => newPasswordRepeatFocus.refresh(),
    );

    phoneNumberController.addListener(() {
      phoneNumber.value = phoneNumberController.text;
      _validateForm();
    });

    firstNameController.addListener(() {
      firstName.value = firstNameController.text;
      _validateForm();
    });

    lastNameController.addListener(() {
      lastName.value = lastNameController.text;
      _validateForm();
    });

    otpController.addListener(() {
      otpCode.value = otpController.text;
    });

    passwordcontroller.addListener(() {
      password.value = passwordcontroller.text;
    });

    nicknamecontroller.addListener(() {
      nickname.value = nicknamecontroller.text;
    });

    emailcontroller.addListener(() {
      email.value = emailcontroller.text;
    });

    resetMailController.addListener(() {
      resetMail.value = resetMailController.text;
    });

    resetOtpController.addListener(() {
      resetOtp.value = resetOtpController.text;
    });

    newPasswordController.addListener(() {
      newPassword.value = newPasswordController.text;
    });

    newPasswordRepeatController.addListener(() {
      newPasswordRepeat.value = newPasswordRepeatController.text;
    });
  }

  @override
  void onClose() {
    emailcontroller.dispose();
    passwordcontroller.dispose();
    nicknamecontroller.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    otpController.dispose();
    resetMailController.dispose();
    resetOtpController.dispose();
    newPasswordController.dispose();
    newPasswordRepeatController.dispose();
    animationController.dispose();
    _timer?.cancel();
    _timerReset?.cancel();
    _emailAvailabilityDebounce?.cancel();
    _nicknameAvailabilityDebounce?.cancel();
    super.onClose();
  }

  void _validateForm() {
    final valid = firstNameController.text.trim().length >= 3 &&
        phoneNumberController.text.trim().length == 10 &&
        phoneNumberController.text.trim().startsWith("5");
    isFormValid.value = valid;
  }
}
