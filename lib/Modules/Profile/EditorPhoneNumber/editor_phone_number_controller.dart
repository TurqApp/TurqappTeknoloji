import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';

class EditorPhoneNumberController extends GetxController {
  final phoneController = TextEditingController();
  final codeController = TextEditingController();

  final phoneValue = "".obs;
  final codeValue = "".obs;
  final countdown = 0.obs;
  final isCodeSent = false.obs;
  final isBusy = false.obs;
  final UserRepository _userRepository = UserRepository.ensure();

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _loadInitialPhone();

    phoneController.addListener(() {
      phoneValue.value = phoneController.text;
    });

    codeController.addListener(() {
      codeValue.value = codeController.text;
    });
  }

  Future<void> _loadInitialPhone() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = await _userRepository.getUserRaw(uid);
    phoneController.text = (data ?? const {})["phoneNumber"]?.toString() ?? "";
    phoneValue.value = phoneController.text;
  }

  @override
  void onClose() {
    _timer?.cancel();
    phoneController.dispose();
    codeController.dispose();
    super.onClose();
  }

  bool get isPhoneValid {
    final newPhone =
        phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    return newPhone.length == 10 && newPhone.startsWith('5');
  }

  Future<String> _resolveAccountEmail() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return "";

    final authEmail = (current.email ?? "").trim().toLowerCase();
    if (authEmail.isNotEmpty) return authEmail;

    final data = await _userRepository.getUserRaw(current.uid);
    return (((data ?? const {})["email"]) ?? "")
        .toString()
        .trim()
        .toLowerCase();
  }

  Future<void> sendEmailApproval() async {
    if (isBusy.value) return;
    if (countdown.value > 0) {
      AppSnackbar("Uyarı", "Lütfen $countdown saniye bekleyin.");
      return;
    }
    if (!isPhoneValid) {
      AppSnackbar(
          "Uyarı", "Lütfen 5 ile başlayan 10 haneli telefon numarası girin.");
      return;
    }

    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      AppSnackbar("Uyarı", "Oturum bulunamadı. Lütfen tekrar giriş yapın.");
      return;
    }
    final email = await _resolveAccountEmail();
    if (email.isEmpty) {
      AppSnackbar("Uyarı", "Hesabınızda doğrulanacak e-posta bulunamadı.");
      return;
    }

    isBusy.value = true;
    try {
      await current.getIdToken(true);
      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('sendEmailVerificationCode')
          .call({
        "email": email,
        "purpose": "phone_change",
        "newPhone": phoneController.text.trim(),
        "idToken": await current.getIdToken(),
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

  Future<void> confirmAndUpdatePhone() async {
    if (isBusy.value) return;
    if (!isPhoneValid) {
      AppSnackbar(
          "Uyarı", "Lütfen 5 ile başlayan 10 haneli telefon numarası girin.");
      return;
    }

    final code = codeController.text.trim();
    if (code.length != 6) {
      AppSnackbar("Uyarı", "Lütfen 6 haneli onay kodunu girin.");
      return;
    }

    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      AppSnackbar("Uyarı", "Oturum bulunamadı. Lütfen tekrar giriş yapın.");
      return;
    }
    final email = await _resolveAccountEmail();
    if (email.isEmpty) {
      AppSnackbar("Uyarı", "Hesabınızda doğrulanacak e-posta bulunamadı.");
      return;
    }

    isBusy.value = true;
    try {
      await current.getIdToken(true);
      final idToken = await current.getIdToken();

      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('verifyEmailCode')
          .call({
        "email": email,
        "purpose": "phone_change",
        "verificationCode": code,
        "idToken": idToken,
      });

      final result = await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('updateUserPhoneNumberAfterEmailVerification')
          .call({
        "newPhone": phoneController.text.trim(),
        "idToken": idToken,
      });

      final ok = (result.data is Map && (result.data["success"] == true));
      if (!ok) {
        AppSnackbar("Hata", "Telefon numarası güncellenemedi.");
        return;
      }

      Get.back();
      AppSnackbar("Başarılı", "Telefon numaranız güncellendi.");
    } on FirebaseFunctionsException catch (e) {
      AppSnackbar("Uyarı", e.message ?? "Telefon numarası güncellenemedi.");
    } catch (_) {
      AppSnackbar("Hata", "Telefon numarası güncellenemedi.");
    } finally {
      isBusy.value = false;
    }
  }
}
