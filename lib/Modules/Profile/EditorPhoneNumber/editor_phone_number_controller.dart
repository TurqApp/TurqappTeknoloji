import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/netgsm_services.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/phone_account_limiter.dart';

class EditorPhoneNumberController extends GetxController {
  final phoneController = TextEditingController();
  final inputOtp = TextEditingController();
  var isVerified = false.obs;
  var lock = false.obs;
  var countdown = 0.obs;

  String _otpCode = "";
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) {
      phoneController.text = doc["phoneNumber"] ?? "";
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    phoneController.dispose();
    inputOtp.dispose();
    super.onClose();
  }

  Future<void> setData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final newPhone = phoneController.text.trim();
    try {
      final userSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final oldPhone = (userSnap.data() ?? const {})['phoneNumber']?.toString() ?? '';

      if (newPhone == oldPhone) {
        Get.back();
        AppSnackbar("Bilgi", "Telefon numaranız zaten bu numara.");
        return;
      }

      final limiter = PhoneAccountLimiter();
      final check = await limiter.checkCanCreate(newPhone);
      if (!check.allowed) {
        AppSnackbar('Limit Aşıldı', 'Bu telefon numarası için en fazla ${check.limit} hesap oluşturulabilir.');
        return;
      }

      // Move counters first to guarantee capacity
      await limiter.moveUserToNewPhone(uid: uid, oldPhone: oldPhone, newPhone: newPhone);

      // Update user doc
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'phoneNumber': newPhone,
      });

      Get.back();
      AppSnackbar("Başarılı", "Telefon numaranız güncellendi.");
    } on PhoneAccountLimitReached catch (e) {
      AppSnackbar('Limit Aşıldı', e.message);
    } catch (e) {
      AppSnackbar('Hata', 'Telefon numarası güncellenemedi.');
    }
  }

  String generateOtpCode({int length = 6}) {
    final random = Random();
    return List.generate(length, (_) => random.nextInt(10).toString()).join();
  }

  Future<void> sendOtpCode() async {
    if (lock.value) {
      AppSnackbar("Uyarı", "Lütfen $countdown saniye bekleyin.");
      return;
    }

    _otpCode = generateOtpCode();
    print("OTP Kodu: $_otpCode");

    try {
      await NetgsmService().sendRequest(_otpCode, phoneController.text);

      lock.value = true;
      countdown.value = 60;

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (countdown.value > 0) {
          countdown.value--;
        } else {
          lock.value = false;
          timer.cancel();
        }
      });

      AppSnackbar("Kod Gönderildi", "Telefonunuza doğrulama kodu gönderildi.");
    } catch (e) {
      AppSnackbar("Hata", "Kod gönderilemedi.");
      lock.value = false;
      countdown.value = 0;
      _timer?.cancel();
    }
  }

  bool verifyOtp(String input) {
    return input == _otpCode;
  }
}
