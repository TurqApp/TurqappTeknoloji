import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class EditorEmailController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void onInit() {
    super.onInit();
    fetchAndSetUserData();
  }

  Future<void> fetchAndSetUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        emailController.text = data["email"] ?? "";
      }
    }
  }

  Future<void> setData() async {
    final newEmail = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final user = FirebaseAuth.instance.currentUser!;

      // 🔐 Reauthenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // ✉️ Email güncelle
      await user.verifyBeforeUpdateEmail(newEmail);

      // 🗂 Firestore'da email güncelle
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        "email": newEmail,
      });

      Get.back();
      AppSnackbar("Başarılı",
          "E-posta adresiniz güncellendi.\nLütfen gelen kutunuzu kontrol edin ve e-posta adresinizi doğrulayın.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        AppSnackbar("Hatalı Şifre", "Lütfen doğru şifrenizi girin.");
      } else if (e.code == 'requires-recent-login') {
        AppSnackbar("Giriş Gerekli",
            "Bu işlemi gerçekleştirmek için hesabınıza tekrar giriş yapmanız gerekiyor.");
      } else {
        AppSnackbar("Hata", "E-posta güncellenemedi.");
      }
      print("FirebaseAuthException: ${e.toString()}");
    } catch (e) {
      AppSnackbar("Hata", "Bilinmeyen bir hata oluştu. Lütfen tekrar deneyin.");
      print("Genel Hata: ${e.toString()}");
    }
  }
}
