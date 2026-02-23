import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Core/info_message.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart.dart';

class MyTutorings extends StatelessWidget {
  const MyTutorings({super.key});

  Future<void> _initializeData() async {
    final MyTutoringsController controller = Get.find<MyTutoringsController>();
    if (controller.myTutorings.isEmpty &&
        controller.getCurrentUserId() != null) {
      await controller.fetchInitialData(controller.getCurrentUserId()!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ViewModeController viewModeController = Get.put(ViewModeController());

    Get.lazyPut(() => MyTutoringsController());
    Get.lazyPut(
      () => PageLineBarController(pageName: "MyTutorings"),
      tag: "MyTutorings",
    );

    return FutureBuilder(
      future: _initializeData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CupertinoActivityIndicator());
        } else if (snapshot.hasError ||
            Get.find<MyTutoringsController>().errorMessage.value.isNotEmpty) {
          return Center(
            child: Text(
              Get.find<MyTutoringsController>().errorMessage.value.isNotEmpty
                  ? Get.find<MyTutoringsController>().errorMessage.value
                  : "Veri yüklenirken hata oluştu",
              style: TextStyles.textFieldTitle,
            ),
          );
        }
        final MyTutoringsController controller =
            Get.find<MyTutoringsController>();
        final PageLineBarController pageLineBarController =
            Get.find<PageLineBarController>(tag: "MyTutorings");

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                BackButtons(text: "Özel Derslerim"),
                PageLineBar(
                  barList: ["Aktif", "Süresi Doldu"],
                  pageName: "MyTutorings",
                  pageController: controller.pageController,
                ),
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: (index) {
                      controller.selection.value = index;
                      pageLineBarController.selection.value = index;
                      // Avoid recursive animate here; only reflect selection
                    },
                    children: [
                      Obx(
                        () => controller.activeTutorings.isEmpty
                            ? Center(
                                child: Text(
                                  "Aktif özel ders ilanı bulunmuyor.",
                                  style: TextStyles.textFieldTitle,
                                ),
                              )
                            : Container(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: TutoringWidgetBuilder(
                                  tutoringList: controller.activeTutorings,
                                  users: controller.users,
                                  isGridView:
                                      viewModeController.isGridView.value,
                                  infoMessage: Infomessage(
                                    infoMessage:
                                        "Aktif özel ders ilanı bulunmuyor.",
                                  ),
                                ),
                              ),
                      ),
                      Obx(
                        () => controller.expiredTutorings.isEmpty
                            ? Center(
                                child: Text(
                                  "Süresi dolmuş özel ders ilanı bulunmuyor.",
                                  style: TextStyles.textFieldTitle,
                                ),
                              )
                            : Container(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: SingleChildScrollView(
                                  child: TutoringWidgetBuilder(
                                    tutoringList: controller.expiredTutorings,
                                    users: controller.users,
                                    isGridView: false,
                                    infoMessage: Infomessage(
                                      infoMessage:
                                          "Süresi dolmuş özel ders ilanı bulunmuyor.",
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
