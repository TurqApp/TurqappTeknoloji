import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Core/info_message.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';

class MyTutorings extends StatelessWidget {
  const MyTutorings({super.key});

  @override
  Widget build(BuildContext context) {
    final ViewModeController viewModeController = Get.put(ViewModeController());

    Get.put(MyTutoringsController());
    Get.lazyPut(
      () => PageLineBarController(pageName: "MyTutorings"),
      tag: "MyTutorings",
    );

    final MyTutoringsController controller = Get.find<MyTutoringsController>();
    final PageLineBarController pageLineBarController =
        Get.find<PageLineBarController>(tag: "MyTutorings");

    return Obx(
      () {
        if (controller.isLoading.value && controller.myTutorings.isEmpty) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty &&
            controller.myTutorings.isEmpty) {
          return Center(
            child: Text(
              controller.errorMessage.value,
              style: TextStyles.textFieldTitle,
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: Get.back,
              icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
            ),
            title: Text(
              'tutoring.my_listings_title'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                PageLineBar(
                  barList: [
                    'tutoring.published'.tr,
                    'tutoring.expired'.tr,
                  ],
                  pageName: "MyTutorings",
                  pageController: controller.pageController,
                ),
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: (index) {
                      controller.selection.value = index;
                      pageLineBarController.selection.value = index;
                    },
                    children: [
                      Obx(
                        () => controller.activeTutorings.isEmpty
                            ? Center(
                                child: Text(
                                  'tutoring.active_listings_empty'.tr,
                                  style: TextStyles.textFieldTitle,
                                ),
                              )
                            : Builder(
                                builder: (context) {
                                  final content = TutoringWidgetBuilder(
                                    tutoringList: controller.activeTutorings,
                                    users: controller.users,
                                    isGridView:
                                        viewModeController.isGridView.value,
                                    infoMessage: Infomessage(
                                      infoMessage:
                                          'tutoring.active_listings_empty'.tr,
                                    ),
                                  );
                                  if (viewModeController.isGridView.value) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: content,
                                    );
                                  }
                                  return content;
                                },
                              ),
                      ),
                      Obx(
                        () => controller.expiredTutorings.isEmpty
                            ? Center(
                                child: Text(
                                  'tutoring.expired_listings_empty'.tr,
                                  style: TextStyles.textFieldTitle,
                                ),
                              )
                            : SingleChildScrollView(
                                child: TutoringWidgetBuilder(
                                  tutoringList: controller.expiredTutorings,
                                  users: controller.users,
                                  isGridView: false,
                                  allowReactivate: true,
                                  infoMessage: Infomessage(
                                    infoMessage:
                                        'tutoring.expired_listings_empty'.tr,
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
