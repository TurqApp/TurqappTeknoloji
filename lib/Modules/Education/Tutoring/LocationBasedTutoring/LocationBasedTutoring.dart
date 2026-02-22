import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/TextStyles.dart';
import 'package:turqappv2/Core/infoMessage.dart';
import 'package:turqappv2/Modules/Education/Tutoring/LocationBasedTutoring/LocationBasedTutoringController.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringWidgetBuilder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/ViewModeController.dart.dart';
import 'package:turqappv2/Themes/AppIcons.dart';

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
                BackButtons(text: "Özel Ders"),
                Padding(
                  padding: EdgeInsets.only(right: 15),
                  child: Row(
                    children: [
                      Icon(AppIcons.locationSolid, size: 16, color: Colors.red),
                      Obx(
                        () => Text(
                          controller.isLoading.value
                              ? 'Yükleniyor..'
                              : controller.tutoringList.isNotEmpty
                                  ? controller.tutoringList.first.sehir
                                  : 'Konum Bulunamadı',
                          style: TextStyles.bold16Black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(child: CupertinoActivityIndicator());
                  } else if (controller.tutoringList.isEmpty) {
                    return Center(
                      child: Text("Bu bölgede ders ilanı bulunmuyor."),
                    );
                  } else {
                    return SingleChildScrollView(
                      child: TutoringWidgetBuilder(
                        tutoringList: controller.tutoringList,
                        users: controller.users,
                        isGridView: viewModeController.isGridView.value,
                        infoMessage: Infomessage(
                          infoMessage: "Bu bölgede ders ilanı bulunmuyor.",
                        ),
                      ),
                    );
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
