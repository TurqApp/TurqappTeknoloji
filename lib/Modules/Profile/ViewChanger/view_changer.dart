import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import 'view_changer_controller.dart';

class ViewChanger extends StatelessWidget {
  ViewChanger({super.key});
  final userService = CurrentUserService.instance;
  late final ViewChangerController controller;
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ViewChangerController>()) {
      final initialSelection =
          (userService.currentUser?.viewSelection ?? 1).obs;
      Get.put(ViewChangerController(selection: initialSelection));
    }
    controller = Get.find<ViewChangerController>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'view_changer.title'.tr),
            Expanded(
              child: ListView(
                children: [
                  Obx(() {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                              onTap: () {
                                controller.updateViewMode(0);
                                Get.back();
                              },
                              child: selection1()),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Divider(
                              color: Colors.grey.withAlpha(50),
                            ),
                          ),
                          GestureDetector(
                              onTap: () {
                                controller.updateViewMode(1);
                                Get.back();
                              },
                              child: selection2()),
                        ],
                      ),
                    );
                  })
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget selection1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
              child: Padding(
                padding: EdgeInsets.all(3),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.selection.value == 0
                          ? Colors.black
                          : Colors.white),
                ),
              ), // örnek ikon
            ),
            7.pw,
            Text(
              'view_changer.classic'.tr,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratBold"),
            )
          ],
        ),
        7.ph,
        Padding(
          padding: const EdgeInsets.only(left: 33),
          child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                      color: controller.selection.value == 0
                          ? Colors.blueAccent
                          : Colors.grey.withAlpha(50)),
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  child: Image.asset("assets/images/klasikview.webp"))),
        )
      ],
    );
  }

  Widget selection2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
              child: Padding(
                padding: EdgeInsets.all(3),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.selection.value == 1
                          ? Colors.black
                          : Colors.white),
                ),
              ), // örnek ikon
            ),
            7.pw,
            Text(
              'view_changer.modern'.tr,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratBold"),
            )
          ],
        ),
        7.ph,
        Padding(
          padding: const EdgeInsets.only(left: 33),
          child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                      color: controller.selection.value == 1
                          ? Colors.blueAccent
                          : Colors.grey.withAlpha(50)),
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  child: Image.asset("assets/images/modernview.webp"))),
        )
      ],
    );
  }
}
