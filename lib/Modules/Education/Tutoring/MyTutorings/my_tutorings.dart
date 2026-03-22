import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Core/info_message.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';

class MyTutorings extends StatefulWidget {
  MyTutorings({super.key});

  @override
  State<MyTutorings> createState() => _MyTutoringsState();
}

class _MyTutoringsState extends State<MyTutorings> {
  late final MyTutoringsController controller;
  late final String _pageLineBarTag = 'MyTutorings_${identityHashCode(this)}';
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _ownsController = MyTutoringsController.maybeFind() == null;
    controller = MyTutoringsController.ensure();
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(MyTutoringsController.maybeFind(), controller)) {
      Get.delete<MyTutoringsController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ViewModeController viewModeController =
        ViewModeController.ensure(permanent: true);

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
            leadingWidth: 52,
            titleSpacing: 8,
            leading: const AppBackButton(),
            title: AppPageTitle('tutoring.my_listings_title'.tr),
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
                  pageName: _pageLineBarTag,
                  pageController: controller.pageController,
                ),
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: (index) {
                      controller.selection.value = index;
                      syncPageLineBarSelection(_pageLineBarTag, index);
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
