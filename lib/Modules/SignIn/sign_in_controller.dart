import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subdoc_repository.dart';
import 'package:turqappv2/Core/Services/mandatory_follow_service.dart';
import 'package:turqappv2/Core/Services/user_document_schema.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Modules/Splash/splash_view.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/account_session_vault.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/device_session_service.dart';
import 'package:turqappv2/Services/phone_account_limiter.dart';

part 'sign_in_controller_auth_part.dart';
part 'sign_in_controller_account_part.dart';
part 'sign_in_controller_lifecycle_part.dart';
part 'sign_in_controller_signup_part.dart';
part 'sign_in_controller_support_part.dart';

class SignInController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static SignInController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SignInController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static SignInController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SignInController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SignInController>(tag: tag);
  }

  var selection = 0.obs;
  final typedBrandLength = 0.obs;
  final showBrandCursor = true.obs;

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
  var signupPoliciesAccepted = false.obs;
  var showPassword = false.obs;
  var showNewPassword = false.obs;
  var showNewPasswordRepeat = false.obs;

  var isFormValid = false.obs;
  final Rxn<StoredAccount> selectedStoredAccount = Rxn<StoredAccount>();

  var otpTimer = 0.obs;
  Timer? _timer;
  Timer? _emailAvailabilityDebounce;
  Timer? _nicknameAvailabilityDebounce;
  Timer? _typewriterTimer;
  Timer? _cursorBlinkTimer;
  Worker? _selectionWorker;
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
  int _emailAvailabilityRequestId = 0;
  int _nicknameAvailabilityRequestId = 0;

  @override
  void onInit() {
    super.onInit();
    _handleLifecycleInit();
  }

  @override
  void onClose() {
    _handleLifecycleClose();
    super.onClose();
  }
}
