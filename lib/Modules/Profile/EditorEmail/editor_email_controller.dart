import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class EditorEmailController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  final countdown = 0.obs;
  final isCodeSent = false.obs;
  final isBusy = false.obs;
  final isEmailConfirmed = false.obs;

  Timer? _timer;
  final UserRepository _userRepository = UserRepository.ensure();

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

  void _seedFromCurrentSources() {
    final authUser = FirebaseAuth.instance.currentUser;
    final currentUser = CurrentUserService.instance.currentUser;
    final seededEmail = currentUser?.email.trim().isNotEmpty == true
        ? currentUser!.email.trim()
        : (authUser?.email ?? '').trim();
    if (seededEmail.isNotEmpty) {
      emailController.text = seededEmail;
    }
    isEmailConfirmed.value = (currentUser?.email.isNotEmpty == true &&
            CurrentUserService.instance.emailVerifiedRx.value) ||
        authUser?.emailVerified == true;
  }

  Future<void> fetchAndSetUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = await _userRepository.getUserRaw(uid);
    if (data != null) {
      emailController.text = data["email"]?.toString() ?? "";
      final firestoreVerified = data["emailVerified"] == true;
      final authVerified =
          FirebaseAuth.instance.currentUser?.emailVerified == true;
      isEmailConfirmed.value = firestoreVerified || authVerified;
    }
  }

  Future<void> sendEmailCode() async {
    if (isBusy.value) return;
    if (countdown.value > 0) {
      AppSnackbar("Uyarı", "Lütfen $countdown saniye bekleyin.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final email = emailController.text.trim().toLowerCase();
    if (user == null) {
      AppSnackbar("Uyarı", "Oturum bulunamadı. Lütfen tekrar giriş yapın.");
      return;
    }
    if (email.isEmpty) {
      AppSnackbar("Uyarı", "Hesabınızda e-posta bulunamadı.");
      return;
    }
    isBusy.value = true;
    try {
      await user.getIdToken(true);
      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('sendEmailVerificationCode')
          .call({
        "email": email,
        "purpose": "email_confirm",
        "idToken": await user.getIdToken(),
      });

      isCodeSent.value = true;
      countdown.value = 60;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (countdown.value > 0) {
          countdown.value--;
        } else {
          timer.cancel();
        }
      });

      AppSnackbar("Başarılı", "Onay kodu e-posta adresinize gönderildi.");
    } on FirebaseFunctionsException catch (e) {
      AppSnackbar("Uyarı", e.message ?? "Onay kodu gönderilemedi.");
    } catch (_) {
      AppSnackbar("Hata", "Onay kodu gönderilemedi.");
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> verifyAndConfirmEmail() async {
    if (isBusy.value) return;

    final user = FirebaseAuth.instance.currentUser;
    final email = emailController.text.trim().toLowerCase();
    final code = codeController.text.trim();

    if (user == null) {
      AppSnackbar("Uyarı", "Oturum bulunamadı. Lütfen tekrar giriş yapın.");
      return;
    }
    if (email.isEmpty) {
      AppSnackbar("Uyarı", "Hesabınızda e-posta bulunamadı.");
      return;
    }
    if (code.length != 6) {
      AppSnackbar("Uyarı", "Lütfen 6 haneli onay kodunu girin.");
      return;
    }

    isBusy.value = true;
    try {
      await user.getIdToken(true);
      final idToken = await user.getIdToken();

      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('verifyEmailCode')
          .call({
        "email": email,
        "purpose": "email_confirm",
        "verificationCode": code,
        "idToken": idToken,
      });

      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('markCurrentEmailVerified')
          .call({"idToken": idToken});

      await FirebaseAuth.instance.currentUser?.reload();
      await CurrentUserService.instance.refreshEmailVerificationStatus(
        reloadAuthUser: true,
      );
      await AccountCenterService.ensure().refreshCurrentAccountMetadata();
      isEmailConfirmed.value = true;

      Get.back();
      AppSnackbar("Başarılı", "E-posta adresiniz onaylandı.");
    } on FirebaseFunctionsException catch (e) {
      AppSnackbar("Uyarı", e.message ?? "E-posta onaylanamadı.");
    } catch (_) {
      AppSnackbar("Hata", "E-posta onaylanamadı.");
    } finally {
      isBusy.value = false;
    }
  }
}
