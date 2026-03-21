import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/create_test.dart';
import 'package:turqappv2/Modules/Education/Tests/LessonsBasedTests/lesson_based_tests.dart';
import 'package:turqappv2/Modules/Education/Tests/MyTestResults/my_test_results.dart';
import 'package:turqappv2/Modules/Education/Tests/MyTests/my_tests.dart';
import 'package:turqappv2/Modules/Education/Tests/SavedTests/saved_tests.dart';
import 'package:turqappv2/Modules/Education/Tests/SearchTests/search_tests.dart';
import 'package:turqappv2/Modules/Education/Tests/TestEntry/test_entry.dart';
import 'package:turqappv2/Modules/Education/Tests/tests_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/tests_grid.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_assets.dart';
import 'package:turqappv2/Core/Widgets/skeleton_loader.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class Tests extends StatefulWidget {
  const Tests({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });
  final bool embedded;
  final bool showEmbeddedControls;

  @override
  State<Tests> createState() => _TestsState();
}

class _TestsState extends State<Tests> {
  late final TestsController controller;
  late final String _controllerTag;
  ScrollController get _scrollController => controller.scrollController;

  bool get embedded => widget.embedded;
  bool get showEmbeddedControls => widget.showEmbeddedControls;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'tests_${embedded ? 'embedded' : 'root'}_${identityHashCode(this)}';
    controller = TestsController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    final existing = TestsController.maybeFind(tag: _controllerTag);
    if (identical(existing, controller)) {
      Get.delete<TestsController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = Expanded(
      child: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.black,
        onRefresh: controller.getData,
        child: Container(
          color: Colors.white,
          child: ListView(
            controller: _scrollController,
            children: [
              EducationSlider(
                imageList: [
                  AppAssets.test1,
                  AppAssets.test2,
                  AppAssets.test3,
                ],
              ),
              20.ph,
              SizedBox(
                height: 85,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  itemCount: dersler.length,
                  itemBuilder: (context, index) {
                    if (index >= dersRenkleri.length ||
                        index >= derslerIconsOutlined.length) {
                      return SizedBox.shrink();
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        right: 7,
                        left: index == 0 ? 20 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Get.to(
                            () => LessonBasedTests(
                              testTuru: dersler[index],
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 70,
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: dersRenkleri[index],
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(40),
                                  ),
                                ),
                                child: Icon(
                                  derslerIconsOutlined[index],
                                  color: Colors.white,
                                ),
                              ),
                              12.ph,
                              Text(
                                dersler[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (!embedded)
                GestureDetector(
                  onTap: () {
                    Get.to(() => SearchTests());
                  },
                  child: Container(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 15,
                        right: 15,
                        bottom: 15,
                      ),
                      child: Container(
                        height: 50,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.all(
                            Radius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                AppIcons.search,
                                color: Colors.pink,
                              ),
                              12.pw,
                              Expanded(
                                child: Text(
                                  "common.search".tr,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontFamily: "Montserrat",
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Obx(
                  () => controller.isLoading.value
                      ? EducationGridSkeleton(itemCount: 4)
                      : controller.list.isEmpty
                          ? Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "tests.no_shared".tr,
                                style: TextStyle(
                                  fontFamily: "MontserratMedium",
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 5.0,
                                mainAxisSpacing: 5.0,
                                childAspectRatio: 0.48,
                              ),
                              itemCount: controller.list.length,
                              itemBuilder: (context, index) {
                                return TestsGrid(
                                  key: ValueKey(
                                    controller.list[index].docID,
                                  ),
                                  model: controller.list[index],
                                );
                              },
                            ),
                ),
              ),
              Obx(() => controller.isLoadingMore.value
                  ? Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  : SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );

    final overlays = [
      ScrollTotopButton(
        scrollController: _scrollController,
        visibilityThreshold: 350,
      ),
      Obx(
        () => Positioned(
          bottom: 20,
          right: 20,
          child: Visibility(
            visible: controller.scrollOffset.value <= 350,
            child: ActionButton(
              context: context,
              menuItems: [
                PullDownMenuItem(
                  icon: CupertinoIcons.bookmark,
                  title: 'common.saved'.tr,
                  onTap: () {
                    Get.to(() => SavedTests());
                  },
                ),
                PullDownMenuItem(
                  icon: Icons.history,
                  title: 'pasaj.common.my_results'.tr,
                  onTap: () {
                    Get.to(() => MyTestResults());
                  },
                ),
                PullDownMenuItem(
                  icon: CupertinoIcons.doc_text,
                  title: 'tests.my_tests_title'.tr,
                  onTap: () {
                    Get.to(() => MyTests());
                  },
                ),
                PullDownMenuItem(
                  icon: Icons.add,
                  title: 'common.create'.tr,
                  onTap: () {
                    Get.to(() => CreateTest());
                  },
                ),
                PullDownMenuItem(
                  icon: Icons.exit_to_app,
                  title: 'tests.join_button'.tr,
                  onTap: () {
                    Get.to(() => TestEntry());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    if (embedded) {
      return Stack(
        children: [
          Column(children: [bodyContent]),
          if (showEmbeddedControls) ...overlays,
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: Icon(
                        AppIcons.arrowLeft,
                        color: Colors.black,
                        size: 25,
                      ),
                    ),
                    TypewriterText(
                      text: "tests.title".tr,
                    ),
                  ],
                ),
                bodyContent,
              ],
            ),
            ...overlays,
          ],
        ),
      ),
    );
  }
}
