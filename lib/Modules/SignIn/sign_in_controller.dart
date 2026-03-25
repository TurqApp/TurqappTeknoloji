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
part 'sign_in_controller_fields_part.dart';
part 'sign_in_controller_lifecycle_part.dart';
part 'sign_in_controller_signup_part.dart';
part 'sign_in_controller_support_part.dart';

class SignInController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static SignInController ensure({String? tag, bool permanent = false}) =>
      maybeFind(tag: tag) ??
      Get.put(SignInController(), tag: tag, permanent: permanent);

  static SignInController? maybeFind({String? tag}) =>
      Get.isRegistered<SignInController>(tag: tag)
          ? Get.find<SignInController>(tag: tag)
          : null;

  final selection = 0.obs;
  final typedBrandLength = 0.obs;
  final showBrandCursor = true.obs;
  final _controllers = _SignInTextControllers();
  final _focuses = _SignInFocusNodes();
  final _state = _SignInStateFields();

  final otpTimer = 0.obs;
  Timer? _timer, _emailAvailabilityDebounce, _nicknameAvailabilityDebounce;
  Timer? _typewriterTimer, _cursorBlinkTimer;
  Worker? _selectionWorker;
  final signupCodeRequested = false.obs, otpRequestInFlight = false.obs;

  final otpTimerReset = 0.obs;
  Timer? _timerReset;
  final resetCodeRequested = false.obs, resetOtpRequestInFlight = false.obs;
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
