import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:turqappv2/Core/sizes.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'package:turqappv2/Themes/app_fonts.dart';

import 'social_qr_code_controller.dart';

class SocialQrCode extends StatelessWidget {
  final String userID;
  SocialQrCode({super.key, required this.userID});
  late final SocialQrCodeController controller;
  final user = Get.find<FirebaseMyStore>();
  @override
  Widget build(BuildContext context) {
    controller = Get.put(SocialQrCodeController(userID: userID));
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.secondColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Icon(CupertinoIcons.xmark,
                          color: Colors.white, size: 25),
                    ),
                    Obx(() {
                      return Text(
                        controller.nickname.value,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: FontSizes.size18,
                            fontFamily: AppFontFamilies.mbold),
                      );
                    }),
                    TextButton(
                      onPressed: () {
                        controller.showQrScannerModal();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Icon(CupertinoIcons.camera,
                          color: Colors.white, size: 25),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              child: QrImageView(
                                data: user.userID.value,
                                version: QrVersions.auto,
                                size: 250.0,
                                backgroundColor: Colors.white,
                                embeddedImage: AssetImage(
                                    "assets/images/logogradient.webp"),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 
                                  0.1), // Gölge rengi (opacity ile yumuşatılır)
                              spreadRadius: 2, // Gölgenin yayılma alanı
                              blurRadius: 2, // Gölge yumuşaklığı
                              offset: Offset(0, 0), // X ve Y ekseninde kaydırma
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  controller.shareProfile();
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                              color:
                                                  Colors.grey.withAlpha(50))),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Icon(
                                          CupertinoIcons.share,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Text(
                                      "Paylaş",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: "MontserratMedium"),
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              GestureDetector(
                                onTap: () {
                                  controller.copyLink();
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                              color:
                                                  Colors.grey.withAlpha(50))),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Icon(
                                          CupertinoIcons.link,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Text(
                                      "Linki Kopyala",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: "MontserratMedium"),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
