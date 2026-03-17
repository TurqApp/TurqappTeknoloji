import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/pasaj_selection_chip.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateAnswerKey/create_answer_key_controller.dart';

class CreateAnswerKey extends StatelessWidget {
  final Function onBack;

  const CreateAnswerKey({required this.onBack, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateAnswerKeyController(onBack));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Optik Form Oluştur"),
            _home(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCevap(
    BuildContext context,
    CreateAnswerKeyController controller,
  ) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Container(
            height: 50,
            color: Colors.grey.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  hintText: "Sınavınıza bir ad verin",
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontFamily: "MontserratMedium",
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 7),
              GestureDetector(
                onTap: () => controller.selectDateTime(context),
                child: Container(
                  height: 45,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Sınav Tarih Saat",
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: "MontserratBold",
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'dd MMMM yyyy - HH:mm',
                            ).format(controller.selectedDateTime.value),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(),
              GestureDetector(
                onTap: controller.toggleSinavSureleri,
                child: Container(
                  height: 45,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Sınav Süresi",
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: "MontserratBold",
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            "${controller.sinavSuresiCount.value} dk",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => PasajSelectionChip(
                  label: "5 Cevap",
                  selected: controller.selection.value == 5,
                  onTap: () => controller.setSelection(5),
                  height: 50,
                  borderRadius: BorderRadius.zero,
                  fontSize: 15,
                ),
              ),
            ),
            Expanded(
              child: Obx(
                () => PasajSelectionChip(
                  label: "4 Cevap",
                  selected: controller.selection.value == 4,
                  onTap: () => controller.setSelection(4),
                  height: 50,
                  borderRadius: BorderRadius.zero,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _home(BuildContext context, CreateAnswerKeyController controller) {
    final questionLabelWidth =
        (MediaQuery.of(context).size.width * 0.26).clamp(84.0, 100.0);

    return Expanded(
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Obx(
                  () => ListView.builder(
                    itemCount: controller.selections.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildTotalCevap(context, controller);
                      } else if (index == controller.selections.length + 1) {
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: controller.addSelection,
                              child: Container(
                                height: 70,
                                alignment: Alignment.center,
                                color: Colors.grey.withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.black,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Sınavınızın, doğru cevap şıklarını giriniz",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () => controller.saveForm(context),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: Container(
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Kaydet",
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
                        );
                      } else {
                        final actualIndex = index - 1;
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: questionLabelWidth,
                                  height: 50,
                                  alignment: Alignment.center,
                                  color: actualIndex % 2 == 0
                                      ? Colors.pink.withValues(alpha: 0.05)
                                      : Colors.pink.withValues(alpha: 0.1),
                                  child: Text(
                                    "${actualIndex + 1}. Soru",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 50,
                                    color: actualIndex % 2 == 0
                                        ? Colors.pink.withValues(alpha: 0.05)
                                        : Colors.pink.withValues(alpha: 0.12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Obx(
                                        () => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            for (var i = 0;
                                                i < controller.selection.value;
                                                i++)
                                              GestureDetector(
                                                onTap: () =>
                                                    controller.updateSelection(
                                                  actualIndex,
                                                  [
                                                    "A",
                                                    "B",
                                                    "C",
                                                    "D",
                                                    "E",
                                                  ][i],
                                                ),
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: controller
                                                                    .selections[
                                                                actualIndex] ==
                                                            [
                                                              "A",
                                                              "B",
                                                              "C",
                                                              "D",
                                                              "E",
                                                            ][i]
                                                        ? Colors.green
                                                        : Colors.white,
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                      Radius.circular(50),
                                                    ),
                                                    border: Border.all(
                                                      color: controller
                                                                      .selections[
                                                                  actualIndex] ==
                                                              [
                                                                "A",
                                                                "B",
                                                                "C",
                                                                "D",
                                                                "E",
                                                              ][i]
                                                          ? Colors.green
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    [
                                                      "A",
                                                      "B",
                                                      "C",
                                                      "D",
                                                      "E",
                                                    ][i],
                                                    style: TextStyle(
                                                      color: controller
                                                                      .selections[
                                                                  actualIndex] ==
                                                              [
                                                                "A",
                                                                "B",
                                                                "C",
                                                                "D",
                                                                "E",
                                                              ][i]
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (controller.selections.length > 1)
                                  GestureDetector(
                                    onTap: () => controller.removeSelection(
                                      actualIndex,
                                    ),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      alignment: Alignment.center,
                                      color: actualIndex % 2 == 0
                                          ? Colors.pink.withValues(alpha: 0.05)
                                          : Colors.pink.withValues(alpha: 0.12),
                                      child: const Icon(
                                        Icons.remove_circle_outlined,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          Obx(
            () => controller.showSinavSureleri.value
                ? Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: controller.toggleSinavSureleri,
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.00001),
                          ),
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.width,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "Sınav Süresi Seç",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: sinavSureleri.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () => controller.selectSinavSuresi(
                                        sinavSureleri[index],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 20,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Obx(
                                              () => Text(
                                                "${sinavSureleri[index]} dk",
                                                style: TextStyle(
                                                  color: controller
                                                              .sinavSuresiCount
                                                              .value ==
                                                          sinavSureleri[index]
                                                      ? Colors.indigo
                                                      : Colors.black,
                                                  fontSize: 18,
                                                  fontFamily: controller
                                                              .sinavSuresiCount
                                                              .value ==
                                                          sinavSureleri[index]
                                                      ? "MontserratBold"
                                                      : "MontserratMedium",
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
