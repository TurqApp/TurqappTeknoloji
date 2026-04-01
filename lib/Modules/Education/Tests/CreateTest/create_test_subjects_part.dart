part of 'create_test.dart';

extension CreateTestSubjectsPart on _CreateTestState {
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
