import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSonuclariPreview/sinav_sonuclari_preview_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class SinavSonuclariPreview extends StatefulWidget {
  final SinavModel model;

  const SinavSonuclariPreview({super.key, required this.model});

  @override
  State<SinavSonuclariPreview> createState() => _SinavSonuclariPreviewState();
}

class _SinavSonuclariPreviewState extends State<SinavSonuclariPreview> {
  late final String _tag;
  late final SinavSonuclariPreviewController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _tag =
        'practice_results_preview_${widget.model.docID}_${identityHashCode(this)}';
    if (Get.isRegistered<SinavSonuclariPreviewController>(tag: _tag)) {
      controller = Get.find<SinavSonuclariPreviewController>(tag: _tag);
      _ownsController = false;
    } else {
      controller = Get.put(
        SinavSonuclariPreviewController(model: widget.model),
        tag: _tag,
      );
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<SinavSonuclariPreviewController>(tag: _tag) &&
        identical(
          Get.find<SinavSonuclariPreviewController>(tag: _tag),
          controller,
        )) {
      Get.delete<SinavSonuclariPreviewController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BackButtons(text: 'practice.results_title'.tr),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? Center(
                        child: CupertinoActivityIndicator(),
                      )
                    : controller.isInitialized.value &&
                            controller.soruList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.black,
                                    size: 40,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'practice.preview_no_questions'.tr,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: Colors.white,
                            backgroundColor: Colors.black,
                            onRefresh: controller.getYanitlar,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Obx(() {
                                    final groupedQuestions =
                                        <String, List<SoruModel>>{};
                                    for (var soru in controller.soruList) {
                                      if (!groupedQuestions.containsKey(
                                        soru.ders,
                                      )) {
                                        groupedQuestions[soru.ders] = [];
                                      }
                                      groupedQuestions[soru.ders]!.add(soru);
                                    }

                                    return Column(
                                      children: groupedQuestions.keys
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map((
                                        entry,
                                      ) {
                                        int index = entry.key;
                                        var ders = entry.value;
                                        int soruIndex = 1;

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () => controller
                                                  .toggleCategory(ders),
                                              child: Container(
                                                height: 45,
                                                color: tumderslerColors[index],
                                                alignment: Alignment.centerLeft,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 15,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(ders,
                                                          style: TextStyles
                                                              .bold18White),
                                                      Icon(
                                                        controller.expandedCategories[
                                                                    ders] ??
                                                                false
                                                            ? AppIcons.up
                                                            : AppIcons.down,
                                                        color: Colors.white,
                                                        size: 18,
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Obx(
                                              () =>
                                                  controller.expandedCategories[
                                                              ders] ??
                                                          false
                                                      ? Column(
                                                          children:
                                                              groupedQuestions[
                                                                      ders]!
                                                                  .map((
                                                            soru,
                                                          ) {
                                                            return buildSoruCard(
                                                              soru,
                                                              soruIndex++,
                                                              controller,
                                                            );
                                                          }).toList(),
                                                        )
                                                      : SizedBox.shrink(),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    );
                                  }),
                                  15.ph,
                                  Obx(
                                    () => controller.isInitialized.value &&
                                            controller.dersVeSonuclar.isEmpty
                                        ? Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.black,
                                                  size: 40,
                                                ),
                                                SizedBox(height: 10),
                                                Text(
                                                  'practice.preview_no_results'
                                                      .tr,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontFamily:
                                                        "MontserratMedium",
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          )
                                        : Column(
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  left: 20,
                                                  right: 20,
                                                  bottom: 15,
                                                  top: 100,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 3,
                                                      child: Text(
                                                        'practice.lesson_header'
                                                            .tr,
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 15,
                                                          fontFamily:
                                                              "MontserratBold",
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        "tests.correct".tr,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 15,
                                                          fontFamily:
                                                              "MontserratBold",
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        "tests.wrong".tr,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 15,
                                                          fontFamily:
                                                              "MontserratBold",
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        "tests.blank".tr,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 15,
                                                          fontFamily:
                                                              "MontserratBold",
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        "tests.net".tr,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 15,
                                                          fontFamily:
                                                              "MontserratBold",
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              for (var item
                                                  in controller.dersVeSonuclar)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    left: 20,
                                                    right: 20,
                                                    bottom: 15,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 3,
                                                        child: Text(item.ders,
                                                            style: TextStyles
                                                                .medium15Black),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                            item.dogru
                                                                .toString(),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyles
                                                                .regular15Black),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                            item.yanlis
                                                                .toString(),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyles
                                                                .regular15Black),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                            item.bos.toString(),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyles
                                                                .regular15Black),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                            item.net.toString(),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyles
                                                                .regular15Black),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                  ),
                                  SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color determineChoiceColor(
    int index,
    String choice,
    SinavSonuclariPreviewController controller,
  ) {
    if (choice == controller.soruList[index].dogruCevap &&
        controller.yanitlar[index] == "") {
      return Colors.orangeAccent;
    } else if (choice == controller.soruList[index].dogruCevap) {
      return Colors.green;
    } else if (choice == controller.yanitlar[index]) {
      return Colors.red;
    } else {
      return Colors.white;
    }
  }

  Color determineChoiceTextColor(
    int index,
    String choice,
    SinavSonuclariPreviewController controller,
  ) {
    if (choice == controller.soruList[index].dogruCevap &&
        controller.yanitlar[index] == "") {
      return Colors.white;
    } else if (choice == controller.soruList[index].dogruCevap) {
      return Colors.white;
    } else if (choice == controller.yanitlar[index]) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }

  Widget buildChoices(
    SoruModel soru,
    int index,
    SinavSonuclariPreviewController controller,
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
                  if (choice == soru.dogruCevap)
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
                      color: determineChoiceColor(index, choice, controller),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      choice,
                      style: TextStyle(
                        color: determineChoiceTextColor(
                          index,
                          choice,
                          controller,
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

  Widget buildSoruCard(
    SoruModel soru,
    int index,
    SinavSonuclariPreviewController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topLeft,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: CachedNetworkImage(
                  imageUrl: soru.soru,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CupertinoActivityIndicator(),
                  ),
                  errorWidget: (context, url, error) => Text(
                    "practice.question_image_failed".tr,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Container(
                  height: 40,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "tests.question_number".trParams({
                      "index": index.toString(),
                    }),
                    style: TextStyles.bold18Black,
                  ),
                ),
              ),
            ],
          ),
          buildChoices(soru, index - 1, controller),
        ],
      ),
    );
  }
}
