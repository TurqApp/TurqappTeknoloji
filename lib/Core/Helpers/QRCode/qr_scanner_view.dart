import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:turqappv2/Core/sizes.dart';
import 'package:turqappv2/Core/Helpers/QRCode/qr_scanner_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'package:turqappv2/Themes/app_fonts.dart';

class QrScannerView extends StatelessWidget {
  final controller = Get.put(QrScannerController());

  QrScannerView({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            width: 70,
            height: 3,
            decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(40))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "QR Kodu Tara",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: FontSizes.size20,
                    fontFamily: AppFontFamilies.mbold),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          child: SizedBox(
            width: 350,
            height: 350,
            child: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                final code = barcode.rawValue;
                if (code != null && code.isNotEmpty) {
                  controller.onDetect(code);
                }
                if (code.toString().length == 28) {
                  Get.to(() => SocialProfile(userID: code.toString()));
                }
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(25),
          child: Text(
            "Yeni tanıştığınız insanların profilinde bulunan qr kodunu okutarak, onun profiline\nanına gidebilirsin",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textBlack,
                fontSize: FontSizes.size14,
                fontFamily: AppFontFamilies.mmedium),
          ),
        ),
      ],
    );
  }
}
