import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import '../../../Core/Helpers/QRCode/qr_scanner_view.dart';

class SocialQrCodeController extends GetxController {
  String userID;
  SocialQrCodeController({required this.userID});
  var nickname = "".obs;
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .get()
        .then((doc) {
      nickname.value = doc.get("nickname");
    });
  }

  void showQrScannerModal() {
    Get.bottomSheet(
      QrScannerView(),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Future<void> shareProfile() async {
    String profileLink =
        'https://turqapp.com/user/$userID'; // Dinamik hale getirilebilir
    await SharePlus.instance.share(ShareParams(text: profileLink));
  }

  Future<void> copyLink() async {
    String profileLink = 'https://turqapp.com/user/$userID';
    await Clipboard.setData(ClipboardData(text: profileLink));
    AppSnackbar("Link Kopyalandı", "Profil linki panoya kopyalandı");
  }
}
