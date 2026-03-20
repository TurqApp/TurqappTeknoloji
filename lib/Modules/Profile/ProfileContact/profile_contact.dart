import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';
import 'package:turqappv2/Modules/Profile/ProfileContact/profile_contant_controller.dart';

class ProfileContact extends StatelessWidget {
  ProfileContact({super.key});
  final controller = Get.put(ProfileContactController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'profile_contact.title'.tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Obx(() {
                        return Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.phone,
                                          color: Colors.black),
                                      SizedBox(width: 12),
                                      Text(
                                        'profile_contact.call'.tr,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: controller.toggleCallVisibility,
                                  child: TurqAppToggle(
                                      isOn: controller.isCallVisible.value),
                                )
                              ],
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: 12),
                      Obx(() {
                        return Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.at,
                                          color: Colors.black),
                                      SizedBox(width: 12),
                                      Text(
                                        'profile_contact.email'.tr,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: controller.toggleEmailVisibility,
                                  child: TurqAppToggle(
                                    isOn: controller.isEmailVisible.value,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
