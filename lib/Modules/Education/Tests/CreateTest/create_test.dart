import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/create_test_controller.dart';

part 'create_test_body_part.dart';

class CreateTest extends StatelessWidget {
  final TestsModel? model;

  const CreateTest({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateTestController(model));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(
                  text: controller.model != null
                      ? "tests.edit_title".tr
                      : "tests.create_title".tr,
                ),
                Expanded(
                  child: Obx(
                    () => controller.isLoading.value
                        ? const Center(
                            child: CupertinoActivityIndicator(
                              radius: 20,
                              color: Colors.black,
                            ),
                          )
                        : controller.appStore.isEmpty ||
                                controller.googlePlay.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.black,
                                      size: 40,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "tests.create_data_missing".tr,
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
                            : testHazirla(context, controller),
                  ),
                ),
              ],
            ),
            Obx(
              () => controller.showBransh.value
                  ? Stack(
                      children: [
                        GestureDetector(
                          onTap: () => controller.showBransh.value = false,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.width,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(24),
                                  topLeft: Radius.circular(24),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "tests.select_branch".tr,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: bransDersleri.length,
                                        itemBuilder: (context, index) {
                                          return GestureDetector(
                                            onTap: () {
                                              controller.selectedDers.clear();
                                              controller.selectedDers.add(
                                                bransDersleri[index],
                                              );
                                              controller.showBransh.value =
                                                  false;
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 15,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      controller
                                                          .localizedLesson(
                                                        bransDersleri[index],
                                                      ),
                                                      style: TextStyle(
                                                        color: controller
                                                                .selectedDers
                                                                .contains(
                                                          bransDersleri[index],
                                                        )
                                                            ? Colors.indigo
                                                            : Colors.black,
                                                        fontSize: 18,
                                                        fontFamily:
                                                            "MontserratMedium",
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 25,
                                                    height: 25,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                        Radius.circular(
                                                          40,
                                                        ),
                                                      ),
                                                      border: Border.all(
                                                        color: Colors.grey
                                                            .withValues(
                                                                alpha: 0.5),
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                        2.5,
                                                      ),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: controller
                                                                  .selectedDers
                                                                  .contains(
                                                            bransDersleri[
                                                                index],
                                                          )
                                                              ? Colors.indigo
                                                              : Colors.white,
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .all(
                                                            Radius.circular(
                                                              40,
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
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            Obx(
              () => controller.showDiller.value
                  ? Stack(
                      children: [
                        GestureDetector(
                          onTap: () => controller.showDiller.value = false,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.width,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(24),
                                  topLeft: Radius.circular(24),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "tests.select_language".tr,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: yabanciDiller.length,
                                        itemBuilder: (context, index) {
                                          return GestureDetector(
                                            onTap: () {
                                              controller.selectedDil.value =
                                                  yabanciDiller[index];
                                              controller.showDiller.value =
                                                  false;
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 15,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      controller
                                                          .localizedLesson(
                                                        yabanciDiller[index],
                                                      ),
                                                      style: TextStyle(
                                                        color: yabanciDiller[
                                                                    index] ==
                                                                controller
                                                                    .selectedDil
                                                                    .value
                                                            ? Colors.indigo
                                                            : Colors.black,
                                                        fontSize: 18,
                                                        fontFamily:
                                                            "MontserratMedium",
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 25,
                                                    height: 25,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                        Radius.circular(
                                                          40,
                                                        ),
                                                      ),
                                                      border: Border.all(
                                                        color: Colors.grey
                                                            .withValues(
                                                                alpha: 0.5),
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                        2.5,
                                                      ),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: yabanciDiller[
                                                                      index] ==
                                                                  controller
                                                                      .selectedDil
                                                                      .value
                                                              ? Colors.indigo
                                                              : Colors.white,
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .all(
                                                            Radius.circular(
                                                              40,
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
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
