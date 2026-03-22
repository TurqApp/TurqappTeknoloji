import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/sizes.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'my_q_r_code_controller.dart';

class MyQRCode extends StatefulWidget {
  const MyQRCode({super.key});

  @override
  State<MyQRCode> createState() => _MyQRCodeState();
}

class _MyQRCodeState extends State<MyQRCode> {
  late final MyQRCodeController controller;
  late final String _controllerTag;
  final userService = CurrentUserService.instance;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'my_qr_code_${identityHashCode(this)}';
    controller = MyQRCodeController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (MyQRCodeController.maybeFind(tag: _controllerTag) != null &&
        identical(
          MyQRCodeController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<MyQRCodeController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenMyQr),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(CupertinoIcons.xmark,
                        color: Colors.white, size: 25),
                  ),
                  Text(
                    'qr.title'.tr,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: FontSizes.size18,
                        fontFamily: AppFontFamilies.mbold),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.showQrScannerModal();
                    },
                    icon: Icon(CupertinoIcons.camera,
                        color: Colors.white, size: 25),
                  )
                ],
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
                            Obx(
                              () => ClipRRect(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    QrImageView(
                                      data: controller
                                              .profileLink.value.isNotEmpty
                                          ? controller.profileLink.value
                                          : userService.effectiveUserId,
                                      version: QrVersions.auto,
                                      size: 250.0,
                                      backgroundColor: Colors.white,
                                    ),
                                    Container(
                                      width: 42,
                                      height: 42,
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: SvgPicture.asset(
                                        "assets/icons/logo.svg",
                                      ),
                                    ),
                                  ],
                                ),
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
                              color: Colors.black.withValues(
                                  alpha:
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
                                          AppIcons.share,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Text(
                                      'common.share'.tr,
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
                                      'common.copy_link'.tr,
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
                                  controller.downloadQRCode();
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
                                          CupertinoIcons.arrow_down_to_line,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Text(
                                      'common.download'.tr,
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
