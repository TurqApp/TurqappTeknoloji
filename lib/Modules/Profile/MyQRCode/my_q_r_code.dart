import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/sizes.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'my_q_r_code_controller.dart';

part 'my_q_r_code_content_part.dart';

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
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: AppBackButton(
                      iconColor: Colors.white,
                      surfaceColor: Color(0x1FFFFFFF),
                    ),
                  ),
                  Text(
                    'qr.title'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: FontSizes.size18,
                      fontFamily: AppFontFamilies.mbold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.showQrScannerModal();
                    },
                    icon: const Icon(
                      CupertinoIcons.camera,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ],
              ),
              Expanded(child: _buildMyQrCodeContent()),
            ],
          ),
        ),
      ),
    );
  }
}
