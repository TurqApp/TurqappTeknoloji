import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalPreview/optical_preview_controller.dart';

class OpticalPreview extends StatefulWidget {
  final OpticalFormModel model;
  final Function? update;

  const OpticalPreview({
    super.key,
    required this.model,
    this.update,
  });

  @override
  State<OpticalPreview> createState() => _OpticalPreviewState();
}

class _OpticalPreviewState extends State<OpticalPreview> {
  late final OpticalPreviewController controller;
  late final String _controllerTag;

  OpticalFormModel get model => widget.model;
  Function? get update => widget.update;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'optical_preview_${widget.model.docID}_${identityHashCode(this)}';
    controller = Get.isRegistered<OpticalPreviewController>(tag: _controllerTag)
        ? Get.find<OpticalPreviewController>(tag: _controllerTag)
        : Get.put(
            OpticalPreviewController(widget.model, widget.update),
            tag: _controllerTag,
          );
  }

  @override
  void dispose() {
    if (Get.isRegistered<OpticalPreviewController>(tag: _controllerTag) &&
        identical(
          Get.find<OpticalPreviewController>(tag: _controllerTag),
          controller,
        )) {
      Get.delete<OpticalPreviewController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Obx(
              () => controller.selection.value == 1
                  ? Column(
                      children: [
                        Container(
                          height: 70,
                          color: Colors.white,
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              controller.fullName.text,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 25,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: model.cevaplar.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: 10,
                                          right: 20,
                                          top: index == 0 ? 10 : 0,
                                        ),
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: index % 2 == 0
                                                ? Colors.pink.withValues(
                                                    alpha: 0.05,
                                                  )
                                                : Colors.pink.withValues(
                                                    alpha: 0.2,
                                                  ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: 35,
                                                height: 35,
                                                child: Center(
                                                  child: Text(
                                                    "${index + 1}.",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 20,
                                                      fontFamily:
                                                          "MontserratBold",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              for (var item in model.max == 5
                                                  ? [
                                                      "A",
                                                      "B",
                                                      "C",
                                                      "D",
                                                      "E",
                                                    ]
                                                  : ["A", "B", "C", "D"])
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 4.0,
                                                  ),
                                                  child: GestureDetector(
                                                    onTap: () =>
                                                        controller.toggleAnswer(
                                                      index,
                                                      item,
                                                    ),
                                                    child: Obx(
                                                      () => Container(
                                                        width: 40,
                                                        height: 40,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: controller
                                                                          .cevaplar[
                                                                      index] ==
                                                                  item
                                                              ? Colors.black
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            50,
                                                          ),
                                                          border: Border.all(
                                                            color: Colors.black,
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          item,
                                                          style: TextStyle(
                                                            color: controller
                                                                            .cevaplar[
                                                                        index] ==
                                                                    item
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontSize: 20,
                                                            fontFamily:
                                                                "MontserratBold",
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(20),
                                  child: GestureDetector(
                                    onTap: () => controller.handleFinishTest(
                                      context,
                                    ),
                                    child: Container(
                                      height: 45,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.indigo,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        "practice.finish_exam".tr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : controller.selection.value == 0
                      ? Container(
                          color: Colors.white,
                          child: ListView(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(25),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 20),
                                    Text(
                                      "answer_key.exam_started_title".tr,
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 25,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "answer_key.exam_started_body".tr,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Divider(color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text(
                                      "answer_key.exam_information_title".tr,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: Text(
                                            "1-)",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontFamily: "MontserratBold",
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "answer_key.exam_information_step1"
                                                .tr,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontFamily: "MontserratMedium",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 15),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: Text(
                                            "2-)",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontFamily: "MontserratBold",
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "answer_key.exam_information_step2"
                                                .tr,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontFamily: "MontserratMedium",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 15),
                                    Container(
                                      height: 50,
                                      alignment: Alignment.centerLeft,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.grey.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 15,
                                        ),
                                        child: TextField(
                                          controller: controller.fullName,
                                          maxLines: 1,
                                          keyboardType: TextInputType.text,
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            hintText:
                                                "answer_key.full_name_hint".tr,
                                            hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: "MontserratMedium",
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Container(
                                      height: 50,
                                      alignment: Alignment.centerLeft,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.grey.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 15,
                                        ),
                                        child: TextField(
                                          controller: controller.ogrenciNo,
                                          maxLines: 1,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            hintText:
                                                "answer_key.student_number_hint"
                                                    .tr,
                                            hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: "MontserratMedium",
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    GestureDetector(
                                      onTap: () {
                                        if (controller.fullName.text
                                                .trim()
                                                .length <
                                            6) {
                                          AppSnackbar(
                                            'signup.missing_info_title'.tr,
                                            'answer_key.full_name_required'.tr,
                                          );
                                          return;
                                        }
                                        if (controller.ogrenciNo.text
                                            .trim()
                                            .isEmpty) {
                                          AppSnackbar(
                                            'signup.missing_info_title'.tr,
                                            'answer_key.student_number_required'
                                                .tr,
                                          );
                                          return;
                                        }
                                        controller.startTest();
                                      },
                                      child: Container(
                                        height: 45,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: controller.canStartTest()
                                              ? Colors.indigo
                                              : Colors.grey,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          "answer_key.start_now".tr,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
