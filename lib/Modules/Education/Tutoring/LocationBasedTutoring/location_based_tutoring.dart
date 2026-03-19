import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Core/info_message.dart';
import 'package:turqappv2/Modules/Education/Tutoring/LocationBasedTutoring/location_based_tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class LocationBasedTutoring extends StatelessWidget {
  const LocationBasedTutoring({super.key});

  @override
  Widget build(BuildContext context) {
    final LocationBasedTutoringController controller = Get.put(
      LocationBasedTutoringController(),
    );
    final ViewModeController viewModeController =
        Get.find<ViewModeController>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BackButtons(text: 'tutoring.title'.tr),
                Padding(
                  padding: EdgeInsets.only(right: 15),
                  child: Row(
                    children: [
                      Icon(AppIcons.locationSolid, size: 16, color: Colors.red),
                      Obx(
                        () => Text(
                          controller.isLoading.value
                              ? 'common.loading'.tr
                              : controller.tutoringList.isNotEmpty
                                  ? controller.tutoringList.first.sehir
                                  : 'tutoring.location_missing'.tr,
                          style: TextStyles.bold16Black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: CupertinoActivityIndicator());
                } else if (controller.tutoringList.isEmpty) {
                  return Center(
                    child: Text('tutoring.no_listings_in_region'.tr),
                  );
                } else {
                  final content = SingleChildScrollView(
                    child: TutoringWidgetBuilder(
                      tutoringList: controller.tutoringList,
                      users: controller.users,
                      isGridView: viewModeController.isGridView.value,
                      infoMessage: Infomessage(
                        infoMessage: 'tutoring.no_listings_in_region'.tr,
                      ),
                    ),
                  );
                  if (viewModeController.isGridView.value) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: content,
                    );
                  }
                  return content;
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}
