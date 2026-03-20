import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'optical_form_entry_controller.dart';

class OpticalFormEntry extends StatelessWidget {
  const OpticalFormEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OpticalFormEntryController());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'answer_key.join_exam_title'.tr),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'tests.search_title'.tr,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'tests.join_help'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                focusNode: controller.focusNode,
                                controller: controller.search,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(50),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'answer_key.exam_id_hint'.tr,
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontFamily: "MontserratMedium",
                                  ),
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                                onChanged: (value) =>
                                    controller.searchText.value = value,
                              ),
                            ),
                          ),
                          Obx(
                            () => controller.searchText.value.isNotEmpty
                                ? GestureDetector(
                                    onTap: controller.searchDocID,
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 20),
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.indigo,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          "answer_key.search_optical_form".tr,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                          Obx(
                            () => controller.model.value != null
                                ? Column(
                                    children: [
                                      const SizedBox(height: 20),
                                      GestureDetector(
                                        onTap: () => controller.handleExamTap(
                                          context,
                                        ),
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(12),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(15),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  controller.model.value!.name,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 18,
                                                    fontFamily:
                                                        "MontserratBold",
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "answer_key.total_questions"
                                                          .trParams({
                                                        "count": controller
                                                            .model
                                                            .value!
                                                            .cevaplar
                                                            .length
                                                            .toString(),
                                                      }),
                                                      style: const TextStyle(
                                                        color: Colors.indigo,
                                                        fontSize: 15,
                                                        fontFamily:
                                                            "MontserratMedium",
                                                      ),
                                                    ),
                                                    Text(
                                                      formatTimestamp(
                                                        controller.model.value!
                                                            .baslangic
                                                            .toInt(),
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.purple,
                                                        fontSize: 15,
                                                        fontFamily:
                                                            "MontserratMedium",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () => controller
                                                          .copyDocID(),
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            "ID: ${controller.model.value!.docID}",
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 15,
                                                              fontFamily:
                                                                  'MontserratMedium',
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          const Icon(
                                                            Icons.copy,
                                                            color: Colors.black,
                                                            size: 15,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (controller.model.value!
                                                            .baslangic
                                                            .toInt() <
                                                        DateTime.now()
                                                            .millisecondsSinceEpoch)
                                                      Text(
                                                        "answer_key.start_now"
                                                            .tr,
                                                        style: TextStyle(
                                                          color: Colors.green,
                                                          fontSize: 15,
                                                          fontFamily:
                                                              'MontserratBold',
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey
                                              .withValues(alpha: 0.1),
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Row(
                                            children: [
                                              if (controller
                                                  .avatarUrl.value.isNotEmpty)
                                                ClipRRect(
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(40),
                                                  ),
                                                  child: SizedBox(
                                                    width: 50,
                                                    height: 50,
                                                    child: CachedNetworkImage(
                                                      imageUrl: controller
                                                          .avatarUrl.value,
                                                      fit: BoxFit.cover,
                                                      placeholder: (
                                                        context,
                                                        url,
                                                      ) =>
                                                          const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                                      errorWidget: (
                                                        context,
                                                        url,
                                                        error,
                                                      ) =>
                                                          const Icon(
                                                        Icons.person,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      controller.fullName.value,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 18,
                                                        fontFamily:
                                                            "MontserratBold",
                                                      ),
                                                    ),
                                                    Text(
                                                      "answer_key.teacher_created_info"
                                                          .tr,
                                                      style: TextStyle(
                                                        color: Colors.pink,
                                                        fontSize: 15,
                                                        fontFamily:
                                                            "MontserratMedium",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      "answer_key.result_placeholder".tr,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratBold",
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
            ),
          ],
        ),
      ),
    );
  }
}
