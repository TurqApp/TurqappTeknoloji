import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'editor_email_controller_actions_part.dart';

class EditorEmailController extends GetxController {
  static EditorEmailController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      EditorEmailController(),
      permanent: permanent,
    );
  }

  static EditorEmailController? maybeFind() {
    final isRegistered = Get.isRegistered<EditorEmailController>();
    if (!isRegistered) return null;
    return Get.find<EditorEmailController>();
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  final countdown = 0.obs;
  final isCodeSent = false.obs;
  final isBusy = false.obs;
  final isEmailConfirmed = false.obs;

  Timer? _timer;
  final UserRepository _userRepository = UserRepository.ensure();
  final CurrentUserService _userService = CurrentUserService.instance;

  String get _currentUid => _userService.effectiveUserId;

  void _seedFromCurrentSources() {
    final authUser = FirebaseAuth.instance.currentUser;
    final currentUser = _userService.currentUser;
    final seededEmail = currentUser?.email.trim().isNotEmpty == true
        ? currentUser!.email.trim()
        : (authUser?.email ?? '').trim();
    if (seededEmail.isNotEmpty) {
      emailController.text = seededEmail;
    }
    isEmailConfirmed.value = (currentUser?.email.isNotEmpty == true &&
            _userService.emailVerifiedRx.value) ||
        authUser?.emailVerified == true;
  }

  Future<void> fetchAndSetUserData() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final data = await _userRepository.getUserRaw(
      uid,
      preferCache: true,
      cacheOnly: true,
    );
    if (data != null) {
      final rawEmail = data["email"]?.toString().trim() ?? "";
      if (rawEmail.isNotEmpty) {
        emailController.text = rawEmail;
      }
      final firestoreVerified = data["emailVerified"] == true;
      final authVerified =
          FirebaseAuth.instance.currentUser?.emailVerified == true;
      isEmailConfirmed.value = firestoreVerified || authVerified;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _seedFromCurrentSources();
    unawaited(fetchAndSetUserData());
  }

  @override
  void onClose() {
    _timer?.cancel();
    emailController.dispose();
    codeController.dispose();
    super.onClose();
  }
}
