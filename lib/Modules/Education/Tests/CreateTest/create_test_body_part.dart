part of 'create_test.dart';

extension CreateTestBodyPart on CreateTest {
  Widget testHazirla(BuildContext context, CreateTestController controller) {
    final coverSelectButtonWidth =
        (MediaQuery.of(context).size.width * 0.52).clamp(160.0, 200.0);

    return ListView(
      children: [
        Column(
          children: [
            GestureDetector(
              onTap: () async {
                final pickedFile =
                    await AppImagePickerService.pickSingleImage(context);
                if (pickedFile != null) {
                  final file = pickedFile;
                  final r = await OptimizedNSFWService.checkImage(file);
                  if (r.isNSFW) {
                    controller.imageFile.value = null;
                    AppSnackbar(
                      "common.error".tr,
                      "tests.create_upload_failed".tr,
                      backgroundColor: Colors.red.withValues(alpha: 0.7),
                    );
                  } else {
                    controller.imageFile.value = file;
                  }
                }
              },
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Obx(
                  () => controller.imageFile.value == null
                      ? controller.foundImage.value.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: controller.foundImage.value,
                                cacheManager: TurqImageCacheManager.instance,
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                                placeholder: (_, __) => Container(
                                  color: Colors.grey[200],
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: MediaQuery.of(context).size.width - 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Opacity(
                                      opacity: 0.5,
                                      child: Image.asset(
                                        "assets/education/testgridpreview.webp",
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final pickedFile =
                                            await AppImagePickerService
                                                .pickSingleImage(context);
                                        if (pickedFile != null) {
                                          final file = pickedFile;
                                          final r = await OptimizedNSFWService
                                              .checkImage(file);
                                          if (r.isNSFW) {
                                            controller.imageFile.value = null;
                                            AppSnackbar("common.error".tr,
                                                "tests.create_upload_failed".tr,
                                                backgroundColor: Colors.red
                                                    .withValues(alpha: 0.7));
                                          } else {
                                            controller.imageFile.value = file;
                                          }
                                        }
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 20),
                                        child: SizedBox(
                                          height: 35,
                                          width: coverSelectButtonWidth,
                                          child: Material(
                                            color: Colors.pink,
                                            borderRadius: const BorderRadius.all(
                                              Radius.circular(20),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "tests.cover_select".tr,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontFamily: "MontserratBold",
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                      : ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                          child: Image.file(
                            controller.imageFile.value!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                alignment: Alignment.topLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: controller.aciklama,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.text,
                    inputFormatters: [LengthLimitingTextInputFormatter(35)],
                    decoration: InputDecoration(
                      hintText: "tests.create_description_hint".tr,
                      hintStyle: const TextStyle(
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
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Obx(
                            () => Text(
                              "tests.share_status".trParams({
                                "status": controller.paylasilabilir.value
                                    ? "tests.status.open".tr
                                    : "tests.status.closed".tr,
                              }),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.paylasilabilir.value =
                              !controller.paylasilabilir.value,
                          child: Obx(
                            () => Container(
                              width: 40,
                              height: 25,
                              alignment: controller.paylasilabilir.value
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.3),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              child: Container(
                                width: 25,
                                decoration: BoxDecoration(
                                  color: controller.paylasilabilir.value
                                      ? Colors.indigo
                                      : Colors.grey,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => Text(
                        controller.paylasilabilir.value
                            ? "tests.share_public_info".tr
                            : "tests.share_private_info".tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                    Obx(
                      () => !controller.paylasilabilir.value
                          ? Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "tests.test_id".trParams({
                                        "id": "${controller.testID.value}",
                                      }),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: "${controller.testID.value}",
                                        ),
                                      );
                                      controller.kopyalandi.value = true;
                                    },
                                    child: Text(
                                      controller.kopyalandi.value
                                          ? "common.copied".tr
                                          : "common.copy".tr,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                      ),
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
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.grey.withValues(alpha: 0.5)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    "tests.test_type".tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 85,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: dersler.length,
                itemBuilder: (context, index) {
                  if (index >= dersRenkleri.length ||
                      index >= derslerIconsOutlined.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: EdgeInsets.only(
                      right: 7,
                      left: index == 0 ? 20 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        controller.testTuru.value = dersler[index];
                        controller.selectedDers.clear();
                      },
                      child: SizedBox(
                        width: 70,
                        child: Column(
                          children: [
                            Obx(
                              () => Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: dersRenkleri[index],
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(40),
                                  ),
                                  border: Border.all(
                                    color: controller.testTuru.value ==
                                            dersler[index]
                                        ? Colors.black
                                        : Colors.black
                                            .withValues(alpha: 0.0001),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  derslerIconsOutlined[index],
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Obx(
                              () => Text(
                                controller.localizedTestType(dersler[index]),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: controller.testTuru.value ==
                                          dersler[index]
                                      ? Colors.pink
                                      : Colors.black,
                                  fontFamily: "MontserratMedium",
                                ),
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
            Obx(
              () => controller.testTuru.value == createTestTypeMiddleSchool ||
                      controller.testTuru.value == createTestTypeHighSchool
                  ? buildOrtaOkulLise(context, controller)
                  : controller.testTuru.value == createTestTypePrep
                      ? buildHazirlik(context, controller)
                      : controller.testTuru.value == createTestTypeLanguage
                          ? buildDil(context, controller)
                          : controller.testTuru.value == createTestTypeBranch
                              ? buildBransh(context, controller)
                              : const SizedBox.shrink(),
            ),
            Obx(
              () => controller.showSilButon.value
                  ? Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: controller.deleteTest,
                              child: Container(
                                height: 45,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  "tests.delete_test".tr,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.saveTest(context),
                              child: Container(
                                height: 45,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  "common.save".tr,
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
                    )
                  : (controller.selectedDers.isNotEmpty &&
                          controller.aciklama.text.isNotEmpty &&
                          !controller.showSilButon.value &&
                          (controller.imageFile.value != null ||
                              controller.model != null))
                      ? GestureDetector(
                          onTap: () => controller.prepareTest(context),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              height: 45,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.indigo,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                "tests.prepare_test".tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildOrtaOkulLise(
    BuildContext context,
    CreateTestController controller,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(
                "tests.subjects".tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 95,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.getFilteredDersler().length,
            itemBuilder: (context, index) {
              String ders = controller.getFilteredDersler()[index];
              if (index >= tumderslerColors.length ||
                  index >= tumDerslerIconlar.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.only(right: 7, left: index == 0 ? 20 : 0),
                child: GestureDetector(
                  onTap: () {
                    if (controller.selectedDers.contains(ders)) {
                      controller.selectedDers.remove(ders);
                    } else {
                      controller.selectedDers.add(ders);
                    }
                  },
                  child: SizedBox(
                    width: 70,
                    child: Column(
                      children: [
                        Obx(
                          () => Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: dersRenkleri[index],
                              borderRadius: const BorderRadius.all(
                                Radius.circular(40),
                              ),
                              border: Border.all(
                                color: controller.selectedDers.contains(ders)
                                    ? Colors.black
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              controller.getIconForDers(ders),
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => Text(
                            controller.localizedLesson(ders),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: controller.selectedDers.contains(ders)
                                  ? Colors.pink
                                  : Colors.black,
                              fontFamily: controller.selectedDers.contains(ders)
                                  ? "MontserratBold"
                                  : "MontserratMedium",
                            ),
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
      ],
    );
  }

  Widget buildHazirlik(BuildContext context, CreateTestController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(
                "tests.exam_prep".tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sinavTurleriList.length,
            itemBuilder: (context, index) {
              final item = sinavTurleriList[index];
              return Padding(
                padding: EdgeInsets.only(right: 7, left: index == 0 ? 20 : 0),
                child: GestureDetector(
                  onTap: () {
                    controller.selectedDers.clear();
                    controller.selectedDers.add(item);
                  },
                  child: SizedBox(
                    width: 70,
                    child: Column(
                      children: [
                        Obx(
                          () => Opacity(
                            opacity: 1.0,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: dersRenkleri[index],
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(40),
                                ),
                                border: Border.all(
                                  color: controller.selectedDers.contains(item)
                                      ? Colors.black
                                      : Colors.black.withValues(alpha: 0.0001),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                derslerIconsOutlined[index],
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => Text(
                            controller.localizedLesson(item),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: controller.selectedDers.contains(item)
                                  ? Colors.pink
                                  : Colors.black,
                              fontFamily: "MontserratMedium",
                            ),
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
      ],
    );
  }

  Widget buildDil(BuildContext context, CreateTestController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(
                "tests.foreign_language".tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (var item in hazirlikDersler.take(2))
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      controller.selectedDers.clear();
                      controller.selectedDers.add(item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Obx(
                        () => Container(
                          height: 39,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: controller.selectedDers.contains(item)
                                ? Colors.black
                                : Colors.white,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            border: Border.all(color: Colors.black, width: 0.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Text(
                              controller.localizedLesson(item),
                              style: TextStyle(
                                color: controller.selectedDers.contains(item)
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (var item in hazirlikDersler.sublist(2, 4))
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      controller.selectedDers.clear();
                      controller.selectedDers.add(item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Obx(
                        () => Container(
                          height: 39,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: controller.selectedDers.contains(item)
                                ? Colors.black
                                : Colors.white,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            border: Border.all(color: Colors.black, width: 0.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Text(
                              controller.localizedLesson(item),
                              style: TextStyle(
                                color: controller.selectedDers.contains(item)
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Obx(
          () => controller.selectedDers.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        "tests.select_language".tr,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Obx(
          () => controller.selectedDers.isNotEmpty
              ? GestureDetector(
                  onTap: () => controller.showDiller.value = true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 45,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.selectedDil.value.isNotEmpty
                                  ? controller.localizedLesson(
                                      controller.selectedDil.value,
                                    )
                                  : "tests.select_language".tr,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                            const Icon(Icons.arrow_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget buildBransh(BuildContext context, CreateTestController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(
                "tests.type.branch".tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => controller.showBransh.value = true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(
              () => Container(
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.selectedDers.isNotEmpty
                            ? controller.localizedLesson(
                                controller.selectedDers.first,
                              )
                            : "tests.select_branch".tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      const Icon(Icons.arrow_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
