import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:turqappv2/Core/sizes.dart';
import 'package:turqappv2/Core/Helpers/QRCode/qr_scanner_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'package:turqappv2/Themes/app_fonts.dart';

class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  late final String _controllerTag;
  late final QrScannerController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'qr_scanner_${identityHashCode(this)}';
    if (Get.isRegistered<QrScannerController>(tag: _controllerTag)) {
      controller = Get.find<QrScannerController>(tag: _controllerTag);
    } else {
      controller = Get.put(QrScannerController(), tag: _controllerTag);
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<QrScannerController>(tag: _controllerTag) &&
        identical(
          Get.find<QrScannerController>(tag: _controllerTag),
          controller,
        )) {
      Get.delete<QrScannerController>(tag: _controllerTag);
    }
    super.dispose();
  }

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
                'qr.scan_title'.tr,
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
            'qr.scan_body'.tr,
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
