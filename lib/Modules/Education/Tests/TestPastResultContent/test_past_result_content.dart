import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/MyPastTestResultsPreview.dart/my_past_test_results_preview.dart';
import 'package:turqappv2/Modules/Education/Tests/TestPastResultContent/test_past_result_content_controller.dart';

class TestPastResultContent extends StatefulWidget {
  final TestsModel model;
  final int index;

  const TestPastResultContent({
    super.key,
    required this.index,
    required this.model,
  });

  @override
  State<TestPastResultContent> createState() => _TestPastResultContentState();
}

class _TestPastResultContentState extends State<TestPastResultContent> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final TestPastResultContentController controller;

  TestsModel get model => widget.model;
  int get index => widget.index;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'controller_${widget.model.docID}_${widget.index}';
    _ownsController =
        TestPastResultContentController.maybeFind(tag: _controllerTag) == null;
    controller = TestPastResultContentController.ensure(
      widget.model,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          TestPastResultContentController.maybeFind(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<TestPastResultContentController>(tag: _controllerTag);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.isLoading.value
          ? Padding(
              padding: EdgeInsets.all(15),
              child: Center(child: CupertinoActivityIndicator()),
            )
          : controller.count.value == 0
              ? Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.black, size: 40),
                      SizedBox(height: 10),
                      Text(
                        "tests.result_answer_missing".tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "Montserrat",
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    GestureDetector(
                      onTap: () => Get.to(
                        () => MyPastTestResultsPreview(model: model),
                      ),
                      child: Container(
                        margin:
                            EdgeInsets.only(left: 15, right: 15, bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.all(
                            Radius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 15,
                            right: 15,
                            top: 15,
                            bottom: 7,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(3),
                                ),
                                child: SizedBox(
                                  width: 75,
                                  height: 75,
                                  child: CachedNetworkImage(
                                    imageUrl: model.img,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CupertinoActivityIndicator(),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "tests.type_test".trParams({
                                        'type': model.testTuru,
                                      }),
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                    Text(
                                      "tests.description_test".trParams({
                                        'description': model.aciklama,
                                      }),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                    Text(
                                      timeAgo(controller.timeStamp.value),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                    if (controller.count.value != 0)
                                      Text(
                                        "tests.solve_count".trParams({
                                          'count':
                                              controller.count.value.toString(),
                                        }),
                                        style: TextStyle(
                                          color: Colors.indigo,
                                          fontSize: 12,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
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
    );
  }
}
