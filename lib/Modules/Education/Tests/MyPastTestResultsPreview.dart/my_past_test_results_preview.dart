import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/MyPastTestResultsPreview.dart/my_past_test_results_preview_controller.dart';

class MyPastTestResultsPreview extends StatefulWidget {
  final TestsModel model;

  const MyPastTestResultsPreview({super.key, required this.model});

  @override
  State<MyPastTestResultsPreview> createState() =>
      _MyPastTestResultsPreviewState();
}

class _MyPastTestResultsPreviewState extends State<MyPastTestResultsPreview> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final MyPastTestResultsPreviewController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'test_results_preview_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        MyPastTestResultsPreviewController.maybeFind(tag: _controllerTag) ==
            null;
    controller = MyPastTestResultsPreviewController.ensure(
      widget.model,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          MyPastTestResultsPreviewController.maybeFind(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<MyPastTestResultsPreviewController>(
          tag: _controllerTag,
          force: true,
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "tests.results_title".tr),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? Center(child: CupertinoActivityIndicator())
                    : controller.soruList.isEmpty || controller.yanitlar.isEmpty
                        ? EmptyRow(text: "tests.results_empty".tr)
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        color: Colors.green,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              controller.dogruSayisi.value
                                                  .toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontFamily: "MontserratBold",
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "tests.correct".tr,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        color: Colors.red,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              controller.yanlisSayisi.value
                                                  .toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontFamily: "MontserratBold",
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "tests.wrong".tr,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        color: Colors.orange,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              controller.bosSayisi.value
                                                  .toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontFamily: "MontserratBold",
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "tests.blank".tr,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        color: Colors.indigo,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "${controller.totalPuan.value.toStringAsFixed(0)}/100",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontFamily: "MontserratBold",
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "tests.score".tr,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                for (var index = 0;
                                    index < controller.soruList.length;
                                    index++)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                          offset: Offset(4, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(
                                                left: 15,
                                                right: 15,
                                                top: 15,
                                              ),
                                              child: Text(
                                                "tests.question_number"
                                                    .trParams({
                                                  'index':
                                                      (index + 1).toString(),
                                                }),
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 20,
                                                  fontFamily: "MontserratBold",
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 20,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                controller.soruList[index].img,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Center(
                                              child:
                                                  CupertinoActivityIndicator(),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(
                                              Icons.broken_image,
                                            ),
                                          ),
                                        ),
                                        buildChoices(controller, index),
                                      ],
                                    ),
                                  ),
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

  Widget buildChoices(
    MyPastTestResultsPreviewController controller,
    int index,
  ) {
    return Container(
      height: 50,
      color: Colors.pink.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var choice in ['A', 'B', 'C', 'D', 'E'])
              Stack(
                children: [
                  if (choice == controller.soruList[index].dogruCevap)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: controller.determineChoiceColor(index, choice),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      choice,
                      style: TextStyle(
                        color: controller.determineChoiceTextColor(
                          index,
                          choice,
                        ),
                        fontSize: 20,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
