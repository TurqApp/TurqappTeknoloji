import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/Tests/TestEntry/test_entry_controller.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class TestEntry extends StatefulWidget {
  const TestEntry({super.key});

  @override
  State<TestEntry> createState() => _TestEntryState();
}

class _TestEntryState extends State<TestEntry> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final TestEntryController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'test_entry_${identityHashCode(this)}';
    _ownsController =
        !Get.isRegistered<TestEntryController>(tag: _controllerTag);
    controller = _ownsController
        ? Get.put(TestEntryController(), tag: _controllerTag)
        : Get.find<TestEntryController>(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<TestEntryController>(tag: _controllerTag)) {
      final registeredController =
          Get.find<TestEntryController>(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<TestEntryController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              children: [
                BackButtons(text: "tests.join_title".tr),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
                                  child: TextField(
                                    cursorColor: Colors.black,
                                    controller: controller.textController,
                                    focusNode: controller.focusNode,
                                    onChanged: controller.onTextChanged,
                                    onSubmitted: controller.onTextSubmitted,
                                    decoration: InputDecoration(
                                      icon: Icon(
                                        AppIcons.search,
                                        color: Colors.pink,
                                      ),
                                      hintText: "tests.search_id_hint".tr,
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontFamily: "Montserrat",
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "Montserrat",
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                "tests.join_help".tr,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                              const SizedBox(height: 20),
                              Obx(
                                () => controller.isLoading.value
                                    ? const Center(
                                        child: CupertinoActivityIndicator(
                                          radius: 20,
                                          color: Colors.black,
                                        ),
                                      )
                                    : controller.model.value == null &&
                                            controller.textController.text
                                                    .length >=
                                                10
                                        ? Padding(
                                            padding: const EdgeInsets.all(15),
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.info_outline,
                                                    color: Colors.black,
                                                    size: 40,
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text(
                                                    "tests.join_not_found".tr,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                      fontFamily: "Montserrat",
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : controller.model.value != null
                                            ? SizedBox(
                                                height: 75,
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    SizedBox(
                                                      height: 75,
                                                      width: 75,
                                                      child: AspectRatio(
                                                        aspectRatio: 1,
                                                        child: controller
                                                                .model
                                                                .value!
                                                                .img
                                                                .isNotEmpty
                                                            ? CachedNetworkImage(
                                                                imageUrl: controller
                                                                    .model
                                                                    .value!
                                                                    .img,
                                                                fit: BoxFit
                                                                    .cover,
                                                                placeholder: (
                                                                  context,
                                                                  url,
                                                                ) =>
                                                                    const Center(
                                                                  child:
                                                                      CupertinoActivityIndicator(),
                                                                ),
                                                                errorWidget: (
                                                                  context,
                                                                  url,
                                                                  error,
                                                                ) =>
                                                                    const Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                ),
                                                              )
                                                            : const Center(
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  color: Colors
                                                                      .indigo,
                                                                  strokeWidth:
                                                                      0.5,
                                                                ),
                                                              ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            "tests.type_test"
                                                                .trParams({
                                                              "type": controller
                                                                  .localizedTestType(
                                                                controller
                                                                    .model
                                                                    .value!
                                                                    .testTuru,
                                                              ),
                                                            }),
                                                            maxLines: 1,
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 18,
                                                              fontFamily:
                                                                  "MontserratBold",
                                                            ),
                                                          ),
                                                          Text(
                                                            controller
                                                                .model
                                                                .value!
                                                                .aciklama,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 15,
                                                              fontFamily:
                                                                  "MontserratMedium",
                                                            ),
                                                          ),
                                                          Text(
                                                            controller
                                                                .localizedLessons(
                                                              controller.model
                                                                  .value!
                                                                  .dersler,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              color: Colors
                                                                  .blueAccent,
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
                                              )
                                            : const SizedBox.shrink(),
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
            Obx(
              () => controller.model.value != null
                  ? GestureDetector(
                      onTap: () => controller.joinTest(context),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: SizedBox(
                          height: 50,
                          child: Material(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "tests.join_button".tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
