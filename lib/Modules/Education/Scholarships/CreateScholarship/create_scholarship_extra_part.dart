part of 'create_scholarship_view.dart';

extension CreateScholarshipExtraPart on CreateScholarshipView {
  Widget buildEkBilgiler(
    BuildContext context,
    CreateScholarshipController controller,
  ) {
    final containerDecoration = BoxDecoration(
      color: Colors.grey.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
    );

    const inputDecoration = InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: GestureDetector(
            onTap: () => controller.currentSection.value = 2,
            child: Row(
              children: [
                const Icon(CupertinoIcons.arrow_left, color: Colors.black),
                const SizedBox(width: 12),
                Text('Başvuru Bilgileri', style: TextStyles.headerTextStyle),
              ],
            ),
          ),
        ),
        Text(
          "Ek Bilgiler",
          style: TextStyles.textFieldTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        16.ph,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Miktar (₺)", style: TextStyles.textFieldTitle),
                  Container(
                    decoration: containerDecoration,
                    child: TextFormField(
                      cursorColor: Colors.black,
                      keyboardType: TextInputType.number,
                      decoration: inputDecoration.copyWith(hintText: "Miktar"),
                      controller: controller.tutarController,
                      onChanged: (value) => controller.tutar.value = value,
                      onEditingComplete: () {
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ],
              ),
            ),
            8.pw,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Öğrenci Sayısı", style: TextStyles.textFieldTitle),
                  Container(
                    decoration: containerDecoration,
                    child: TextFormField(
                      cursorColor: Colors.black,
                      keyboardType: TextInputType.number,
                      decoration: inputDecoration.copyWith(hintText: "ör: 4"),
                      controller: controller.ogrenciSayisiController,
                      onChanged: (value) =>
                          controller.ogrenciSayisi.value = value,
                      onEditingComplete: () {
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 15, color: Colors.grey.shade700),
            4.pw,
            Expanded(
              child: Text(
                '\'Miktar\' ve \'Öğrenci Sayısı\' bilgileri başvuru sayfasında görüntülenmemektedir.',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontFamily: "Montserrat",
                ),
              ),
            ),
          ],
        ),
        8.ph,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Mükerrer Durumu", style: TextStyles.textFieldTitle),
                  GestureDetector(
                    onTap: () {
                      AppBottomSheet.show(
                        context: Get.context!,
                        items: ["Alabilir", "Alamaz (KYK Hariç)"],
                        title: "Mükerrer Durumu",
                        selectedItem: controller.mukerrerDurumu.value,
                        onSelect: (value) {
                          controller.mukerrerDurumu.value = value;
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      alignment: Alignment.centerLeft,
                      decoration: containerDecoration,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.mukerrerDurumu.value,
                              style: const TextStyle(color: Colors.black),
                            ),
                            const Icon(CupertinoIcons.chevron_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            8.pw,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Geri Ödemeli", style: TextStyles.textFieldTitle),
                  GestureDetector(
                    onTap: () {
                      AppBottomSheet.show(
                        context: Get.context!,
                        items: ["Evet", "Hayır"],
                        title: "Geri Ödemeli",
                        selectedItem: controller.geriOdemeli.value,
                        onSelect: (value) {
                          controller.geriOdemeli.value = value;
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      alignment: Alignment.centerLeft,
                      decoration: containerDecoration,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.geriOdemeli.value,
                              style: const TextStyle(color: Colors.black),
                            ),
                            const Icon(CupertinoIcons.chevron_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        16.ph,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hedef Kitle", style: TextStyles.textFieldTitle),
                  GestureDetector(
                    onTap: () {
                      AppBottomSheet.show(
                        context: Get.context!,
                        items: ["Nüfusa Göre", "İkamete Göre", "Tüm Türkiye"],
                        title: "Hedef Kitle",
                        selectedItem: controller.hedefKitle.value,
                        onSelect: (value) {
                          controller.hedefKitle.value = value;
                          if (value == "Tüm Türkiye") {
                            controller.sehirler.clear();
                            controller.ilceler.clear();
                          }
                          if (value != "Lisans") {
                            controller.universiteler.clear();
                          }
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      alignment: Alignment.centerLeft,
                      decoration: containerDecoration,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.hedefKitle.value.isEmpty
                                  ? "Hedef Kitle"
                                  : controller.hedefKitle.value,
                              style: const TextStyle(color: Colors.black),
                            ),
                            const Icon(CupertinoIcons.chevron_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        16.ph,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Eğitim Kitlesi", style: TextStyles.textFieldTitle),
                  GestureDetector(
                    onTap: () {
                      AppBottomSheet.show(
                        context: Get.context!,
                        items: [
                          "Hepsi",
                          "Ortaokul",
                          "Lise",
                          "Lisans",
                        ],
                        title: "Eğitim Kitlesi",
                        selectedItem: controller.egitimKitlesi.value,
                        onSelect: (value) {
                          controller.egitimKitlesi.value = value;
                          if (value != "Lisans") {
                            controller.lisansTuru.clear();
                            controller.universiteler.clear();
                          }
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      alignment: Alignment.centerLeft,
                      decoration: containerDecoration,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.egitimKitlesi.value.isEmpty
                                  ? "Eğitim Kitlesi"
                                  : controller.egitimKitlesi.value,
                              style: const TextStyle(color: Colors.black),
                            ),
                            const Icon(CupertinoIcons.chevron_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => controller.egitimKitlesi.value == "Hepsi" ||
                      controller.egitimKitlesi.value == "Ortaokul" ||
                      controller.egitimKitlesi.value == "Lise"
                  ? const SizedBox.shrink()
                  : 8.pw,
            ),
            Obx(() {
              if (controller.egitimKitlesi.value == "Lisans") {
                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Lisans Türü", style: TextStyles.textFieldTitle),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) => MultiSelectBottomSheet2(
                              title: "Lisans Türü Seç",
                              items: [
                                "Ön Lisans",
                                "Lisans",
                                "Yüksek Lisans",
                                "Doktora",
                              ],
                              selectedItems: controller.lisansTuru,
                              onConfirm: (selected) {
                                controller.lisansTuru.assignAll(selected);
                              },
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          alignment: Alignment.centerLeft,
                          decoration: containerDecoration,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Obx(
                            () => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  controller.lisansTuru.isEmpty
                                      ? "Lisans Türü Seçin"
                                      : controller.lisansTuru.length > 1
                                          ? "${controller.lisansTuru.length} tane seçildi"
                                          : controller.lisansTuru.join(", "),
                                  style: const TextStyle(color: Colors.black),
                                ),
                                const Icon(
                                  CupertinoIcons.chevron_down,
                                  size: 20,
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
              return const SizedBox.shrink();
            }),
          ],
        ),
        16.ph,
        Obx(() {
          if (controller.hedefKitle.value == "Nüfusa Göre" ||
              controller.hedefKitle.value == "İkamete Göre") {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country Selection
                Text("Ülke", style: TextStyles.textFieldTitle),
                GestureDetector(
                  onTap: () {
                    ListBottomSheet.show(
                      context: context,
                      items: ["Türkiye"], // Add more countries if needed
                      title: "Ülke Seç",
                      selectedItem: controller.ulke.value.isEmpty
                          ? null
                          : controller.ulke.value,
                      onSelect: (value) {
                        controller.ulke.value = value;
                        // Clear cities and districts if country changes
                        controller.sehirler.clear();
                        controller.ilceler.clear();
                        controller.universiteler.clear();
                      },
                      isSearchable: false,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    alignment: Alignment.centerLeft,
                    decoration: containerDecoration,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.ulke.value.isEmpty
                                ? "Ülke Seçin"
                                : controller.ulke.value,
                            style: const TextStyle(color: Colors.black),
                          ),
                          const Icon(CupertinoIcons.chevron_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // City and District Selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("İl", style: TextStyles.textFieldTitle),
                          GestureDetector(
                            onTap: () {
                              if (controller.ulke.value.isEmpty) {
                                AppSnackbar(
                                    'Hata', 'Lütfen önce bir ülke seçin.');
                                return;
                              }
                              ListBottomSheet.show(
                                context: context,
                                items: controller.iller,
                                title: "İl Seç",
                                selectedItem: controller.sehirler.isNotEmpty
                                    ? controller.sehirler.first
                                    : null,
                                onSelect: (selected) {
                                  controller.sehirler
                                      .clear(); // Single selection
                                  controller.sehirler.add(selected);
                                  // Clear districts and universities that are not valid for the selected city
                                  final validIlceler = controller.ilceler
                                      .where((ilce) => controller
                                          .getDistrictsForSelectedCities()
                                          .contains(ilce))
                                      .toList();
                                  controller.ilceler.assignAll(validIlceler);
                                  final validUniversiteler = controller
                                      .universiteler
                                      .where((uni) =>
                                          uni == 'Tüm Üniversiteler' ||
                                          controller
                                              .getUniversitiesForSelectedCities()
                                              .contains(uni))
                                      .toList();
                                  controller.universiteler
                                      .assignAll(validUniversiteler);
                                },
                                isSearchable: true,
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              alignment: Alignment.centerLeft,
                              decoration: containerDecoration,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Obx(
                                () => Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      controller.sehirler.isEmpty
                                          ? "İl Seçin"
                                          : controller.sehirler.first,
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                    const Icon(CupertinoIcons.chevron_down,
                                        size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.egitimKitlesi.value != "Lisans") ...[
                      8.pw,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("İlçe", style: TextStyles.textFieldTitle),
                            GestureDetector(
                              onTap: () {
                                if (controller.sehirler.isEmpty) {
                                  AppSnackbar(
                                      'Hata', 'Lütfen önce bir il seçin.');
                                  return;
                                }
                                ListBottomSheet.show(
                                  context: context,
                                  items: controller
                                      .getDistrictsForSelectedCities(),
                                  title: "İlçe Seç",
                                  selectedItem: controller.ilceler.isNotEmpty
                                      ? controller.ilceler.first
                                      : null,
                                  onSelect: (selected) {
                                    controller.ilceler
                                        .clear(); // Single selection
                                    controller.ilceler.add(selected);
                                  },
                                  isSearchable: true,
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                alignment: Alignment.centerLeft,
                                decoration: containerDecoration,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Obx(
                                  () => Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        controller.ilceler.isEmpty
                                            ? "İlçe Seçin"
                                            : controller.ilceler.first,
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                      const Icon(CupertinoIcons.chevron_down,
                                          size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
        Obx(
          () => controller.hedefKitle.value == "Nüfusa Göre" ||
                  controller.hedefKitle.value == "İkamete Göre"
              ? const SizedBox(height: 16)
              : const SizedBox.shrink(),
        ),
        Obx(() {
          if (controller.egitimKitlesi.value == "Lisans") {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Üniversiteler", style: TextStyles.textFieldTitle),
                GestureDetector(
                  onTap: () {
                    if (controller.hedefKitle.value != "Tüm Türkiye" &&
                        controller.sehirler.isEmpty) {
                      AppSnackbar('Hata', 'Lütfen önce bir il seçin.');
                      return;
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) => MultiSelectBottomSheet2(
                        title: "Üniversite Seç",
                        items: controller.getUniversitiesForSelectedCities(),
                        selectedItems: controller.universiteler,
                        onConfirm: (selected) {
                          controller.universiteler.assignAll(selected);
                        },
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    alignment: Alignment.centerLeft,
                    decoration: containerDecoration,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.universiteler.isEmpty
                                ? "Üniversite Seçin"
                                : controller.universiteler.contains(
                                    "Tüm Üniversiteler",
                                  )
                                    ? controller.universiteler.join(", ")
                                    : "${controller.universiteler.length} üniversite seçildi",
                            style: const TextStyle(color: Colors.black),
                          ),
                          const Icon(CupertinoIcons.chevron_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  if (controller.universiteler.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Seçilen Üniversiteler:",
                          style: TextStyles.textFieldTitle.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: controller.universiteler.map((uni) {
                            return Chip(
                              backgroundColor: Colors.grey.shade200,
                              label: Text(uni),
                              onDeleted: () {
                                if (uni == 'Tüm Üniversiteler') {
                                  controller.universiteler.clear();
                                } else {
                                  controller.universiteler.remove(uni);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                controller.currentSection.value = 2;
              },
              child: Container(
                height: 40,
                width: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Geri', style: TextStyles.medium15Black),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (controller.tutar.value.isEmpty ||
                    controller.ogrenciSayisi.value.isEmpty ||
                    controller.mukerrerDurumu.value.isEmpty ||
                    controller.geriOdemeli.value.isEmpty ||
                    controller.hedefKitle.value.isEmpty ||
                    controller.egitimKitlesi.value.isEmpty ||
                    (controller.egitimKitlesi.value == "Lisans" &&
                        controller.lisansTuru.isEmpty) ||
                    ((controller.hedefKitle.value == "Nüfusa Göre" ||
                            controller.hedefKitle.value == "İkamete Göre") &&
                        controller
                            .ulke.value.isEmpty) || // Add country validation
                    ((controller.hedefKitle.value == "Nüfusa Göre" ||
                            controller.hedefKitle.value == "İkamete Göre") &&
                        controller.sehirler.isEmpty) ||
                    (controller.egitimKitlesi.value == "Lisans" &&
                        controller.hedefKitle.value != "Tüm Türkiye" &&
                        controller.sehirler.isEmpty &&
                        controller.universiteler.isEmpty)) {
                  AppSnackbar(
                    'Hata',
                    'Lütfen tüm alanları doldurunuz.',
                    backgroundColor: Colors.red.withValues(alpha: 0.7),
                  );
                  return;
                }
                controller.currentSection.value = 4;
              },
              child: Container(
                height: 40,
                width: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('İleri', style: TextStyles.medium15white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
