part of 'create_scholarship_view.dart';

extension CreateScholarshipBasicPart on CreateScholarshipView {
  String _applicationPlaceLabel(String value) {
    switch (value) {
      case 'TurqApp':
        return 'scholarship.application_place_turqapp'.tr;
      case 'Burs Web Site':
      case 'Web Site':
        return 'scholarship.application_place_website'.tr;
      default:
        return value;
    }
  }

  Widget buildTemelBilgiler(
    BuildContext context,
    CreateScholarshipController controller,
  ) {
    final containerDecoration = BoxDecoration(
      color: Colors.grey.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
    );

    const inputDecoration = InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BackButtons(
          text: controller.isEditing.value
              ? "scholarship.edit_title".tr
              : "scholarship.create_title".tr,
        ),
        Text(
          "scholarship.basic_info".tr,
          style: TextStyles.textFieldTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        16.ph,
        Text("scholarship.title_label".tr, style: TextStyles.textFieldTitle),
        4.ph,
        Container(
          alignment: Alignment.center,
          decoration: containerDecoration,
          child: TextFormField(
            cursorColor: Colors.black,
            textCapitalization: TextCapitalization.characters,
            decoration:
                inputDecoration.copyWith(hintText: "scholarship.title_label".tr),
            controller: controller.baslikController,
            onChanged: (value) => controller.baslik.value = value,
          ),
        ),
        16.ph,
        Text("scholarship.provider_label".tr,
            style: TextStyles.textFieldTitle),
        4.ph,
        Container(
          alignment: Alignment.center,
          decoration: containerDecoration,
          child: TextFormField(
            maxLength: 44,
            cursorColor: Colors.black,
            textCapitalization: TextCapitalization.characters,
            decoration: inputDecoration.copyWith(
              hintText: "scholarship.provider_label".tr,
            ),
            controller: controller.bursVerenController,
            inputFormatters: [
              // Allow Turkish letters (both cases) and spaces; we'll uppercase dynamically
              FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü\s]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                String toUpperTr(String s) {
                  return s
                      .replaceAll('i', 'İ')
                      .replaceAll('ı', 'I')
                      .replaceAll('ş', 'Ş')
                      .replaceAll('ğ', 'Ğ')
                      .replaceAll('ç', 'Ç')
                      .replaceAll('ö', 'Ö')
                      .replaceAll('ü', 'Ü')
                      .toUpperCase();
                }

                String text = newValue.text;
                // Normalize to Turkish uppercase first
                text = toUpperTr(text);
                // Reduce multiple spaces to single, but keep a single trailing space if user typed it
                // First collapse internal runs
                text = text.replaceAll(RegExp(r' {2,}'), ' ');

                // Build words ignoring empty segments
                final words = text
                    .trim()
                    .split(RegExp(r'\s+'))
                    .where((w) => w.isNotEmpty)
                    .toList();

                // Enforce max 3 words: if adding a fourth (detected by trailing space after 3rd), block
                if (words.length > 3) {
                  return oldValue;
                }
                if (words.length == 3 && text.endsWith(' ')) {
                  // Prevent starting a 4th word
                  final trimmed = text.trimRight();
                  return TextEditingValue(
                    text: trimmed,
                    selection: TextSelection.collapsed(offset: trimmed.length),
                  );
                }

                // Each word length must be <= 14
                for (final word in words) {
                  if (word.length > 14) {
                    return oldValue;
                  }
                }

                // Allow user to add space at any time; do not auto-insert spaces
                return TextEditingValue(
                  text: text,
                  selection: TextSelection.collapsed(offset: text.length),
                );
              }),
            ],
            onChanged: (value) {
              controller.bursVeren.value = value.trimRight();
              controller.bursVerenController.text = controller.bursVeren.value;
              controller.bursVerenController.selection =
                  TextSelection.collapsed(
                      offset: controller.bursVerenController.text.length);
            },
          ),
        ),
        16.ph,
        Text("scholarship.website_label".tr,
            style: TextStyles.textFieldTitle),
        4.ph,
        Container(
          alignment: Alignment.center,
          decoration: containerDecoration,
          child: TextFormField(
            cursorColor: Colors.black,
            decoration: inputDecoration.copyWith(
              hintText: "scholarship.website_label".tr,
            ),
            controller: controller.websiteController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z0-9\-\._~:/?#[\]@!$&()*+,;=%]'),
              ),
              TextInputFormatter.withFunction((oldValue, newValue) {
                String text = newValue.text;

                // Eğer https:// ile başlamıyorsa veya sadece https:// ise
                if (!text.startsWith("https://") || text.length < 8) {
                  return TextEditingValue(
                    text: "https://",
                    selection: TextSelection.collapsed(offset: 8),
                  );
                }

                // Eğer https:// den sonra sadece / varsa, onu kaldır
                if (text == "https:///") {
                  return TextEditingValue(
                    text: "https://",
                    selection: TextSelection.collapsed(offset: 8),
                  );
                }

                return newValue;
              }),
            ],
            onChanged: (value) {
              controller.website.value = value;
            },
          ),
        ),
        16.ph,
        Text("common.description".tr, style: TextStyles.textFieldTitle),
        4.ph,
        Container(
          decoration: containerDecoration,
          child: TextFormField(
            maxLength: 1000,
            minLines: 3,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration:
                inputDecoration.copyWith(hintText: "common.description".tr),
            controller: controller.aciklamaController,
            onChanged: (value) => controller.aciklama.value = value,
          ),
        ),
        4.ph,
        Text(
          "scholarship.description_help".tr,
          style: TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontFamily: "Montserrat",
          ),
        ),
        20.ph,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Get.to(ScholarshipsView()),
              child: Container(
                height: 40,
                width: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('common.back'.tr, style: TextStyles.medium15Black),
              ),
            ),
            // currentSection.value = 2
            GestureDetector(
              onTap: () {
                if (controller.baslik.value.isEmpty ||
                    controller.bursVeren.value.isEmpty ||
                    controller.website.value.isEmpty ||
                    controller.aciklama.value.isEmpty) {
                  AppSnackbar(
                    'common.error'.tr,
                    'common.fill_all_fields'.tr,
                    backgroundColor: Colors.red.withValues(alpha: 0.7),
                  );
                  return;
                }
                controller.currentSection.value = 2;
              },
              child: Container(
                height: 40,
                width: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('common.continue'.tr,
                    style: TextStyles.medium15white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildBasvuruBilgileri(
    BuildContext context,
    CreateScholarshipController controller,
  ) {
    final dateFormat = DateFormat('dd.MM.yyyy');
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
            onTap: () => controller.currentSection.value = 1,
            child: Row(
              children: [
                const Icon(CupertinoIcons.arrow_left, color: Colors.black),
                const SizedBox(width: 12),
                Text(
                  'scholarship.basic_info'.tr,
                  style: TextStyles.headerTextStyle,
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "scholarship.conditions_label".tr,
              style: TextStyles.textFieldTitle,
            ),
            GestureDetector(
              onTap: () {
                controller.selectedItems.clear();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) => MultipleChoiceBottomSheet(
                    controller: controller,
                    title: "scholarship.conditions_label".tr,
                    items: controller.bursKosullari,
                    selectionType: 'conditions',
                  ),
                );
              },
              child: Text(
                "scholarship.select_from_list".tr,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade900,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ],
        ),
        4.ph,
        Container(
          decoration: containerDecoration,
          child: TextFormField(
            cursorColor: Colors.black,
            minLines: 4,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            controller: controller.basvuruKosullariController,
            decoration: inputDecoration.copyWith(
              hintText: "scholarship.conditions_label".tr,
            ),
            onChanged: (value) => controller.basvuruKosullari.value = value,
          ),
        ),
        16.ph,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "scholarship.required_docs_label".tr,
              style: TextStyles.textFieldTitle,
            ),
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
                  builder: (context) => MultipleChoiceBottomSheet(
                    controller: controller,
                    title: "scholarship.required_docs_label".tr,
                    items: controller.gerekliBelgeler,
                    selectionType: 'documents',
                  ),
                );
              },
              child: Text(
                "scholarship.select_from_list".tr,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade900,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ],
        ),
        4.ph,
        Container(
          decoration: containerDecoration,
          child: TextFormField(
            cursorColor: Colors.black,
            minLines: 4,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            controller: controller.belgelerController,
            decoration: inputDecoration.copyWith(
              hintText: "scholarship.required_docs_label".tr,
            ),
            onChanged: (value) {
              controller.belgeler.value = value
                  .split('\n')
                  .where((item) => item.trim().isNotEmpty)
                  .toList();
            },
          ),
        ),
        16.ph,
        Text(
          "scholarship.award_months_label".tr,
          style: TextStyles.textFieldTitle,
        ),
        4.ph,
        Container(
          decoration: containerDecoration,
          child: Obx(
            () => TextFormField(
              readOnly: true,
              controller: controller.aylarController
                ..text = controller.aylarText.value.isEmpty
                    ? "scholarship.award_months_label".tr
                    : controller.aylarText.value,
              cursorColor: Colors.black,
              textAlignVertical: TextAlignVertical.center,
              decoration: inputDecoration.copyWith(
                hintText: "scholarship.award_months_label".tr,
                suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 20),
              ),
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
                  builder: (context) => MultipleChoiceBottomSheet(
                    controller: controller,
                    title: "scholarship.award_months_label".tr,
                    items: controller.bursVerilecekAylar,
                    selectionType: 'months',
                  ),
                );
              },
            ),
          ),
        ),
        16.ph,
        Text(
          "scholarship.application_place_label".tr,
          style: TextStyles.textFieldTitle,
        ),
        4.ph,
        Container(
          decoration: containerDecoration,
          child: TextFormField(
            readOnly: true,
            controller: controller.basvuruYapilacakYerController,
            cursorColor: Colors.black,
            textAlignVertical: TextAlignVertical.center,
            decoration: inputDecoration.copyWith(
              hintText: "scholarship.application_place_label".tr,
              suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 20),
            ),
            onTap: () {
              AppBottomSheet.show(
                context: Get.context!,
                items: const ["TurqApp", "Burs Web Site"],
                title: "scholarship.application_place_label".tr,
                selectedItem: controller.basvuruYapilacakYer.value,
                itemLabelBuilder: (item) => _applicationPlaceLabel(
                  item.toString(),
                ),
                onSelect: (value) {
                  controller.basvuruYapilacakYer.value = value;
                  controller.basvuruYapilacakYerController.text =
                      _applicationPlaceLabel(value.toString());
                },
              );
            },
          ),
        ),
        16.ph,
        Obx(() {
          if (controller.basvuruYapilacakYer.value == "Burs Web Site") {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "scholarship.application_website_label".tr,
                  style: TextStyles.textFieldTitle,
                ),
                4.ph,
                Container(
                  alignment: Alignment.center,
                  decoration: containerDecoration,
                  child: TextFormField(
                    cursorColor: Colors.black,
                    decoration: inputDecoration.copyWith(
                      hintText: "scholarship.application_website_label".tr,
                    ),
                    controller: controller.basvuruURLController,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    onChanged: (value) {
                      if (!value.startsWith("https://")) {
                        value =
                            "https://${value.replaceFirst(RegExp(r'^https?://'), '')}";
                        controller.basvuruURL.value = value;
                        controller.basvuruURLController.text = value;
                        controller.basvuruURLController.selection =
                            TextSelection.collapsed(offset: value.length);
                      } else {
                        controller.basvuruURL.value = value;
                        controller.basvuruURLController.text = value;
                      }
                    },
                  ),
                ),
                16.ph,
              ],
            );
          } else {
            return const SizedBox.shrink();
          }
        }),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "scholarship.application_dates_label".tr,
                    style: TextStyles.textFieldTitle,
                  ),
                  4.ph,
                  GestureDetector(
                    onTap: () {
                      Get.bottomSheet(
                        FutureDatePickerBottomSheet(
                          initialDate:
                              controller.baslangicTarihi.value.isNotEmpty
                                  ? DateFormat(
                                      'dd.MM.yyyy',
                                    ).parse(controller.baslangicTarihi.value)
                                  : DateTime.now(),
                          onSelected: (DateTime date) {
                            controller.baslangicTarihi.value =
                                dateFormat.format(date);
                          },
                          title: 'scholarship.application_start_date'.tr,
                        ),
                      );
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      height: 50,
                      width: double.infinity,
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
                              controller.baslangicTarihi.value,
                              style: TextStyles.textFieldTitle,
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
                  Text(""),
                  GestureDetector(
                    onTap: () {
                      Get.bottomSheet(
                        FutureDatePickerBottomSheet(
                          initialDate: controller.bitisTarihi.value.isNotEmpty
                              ? DateFormat(
                                  'dd.MM.yyyy',
                                ).parse(controller.bitisTarihi.value)
                              : DateTime.now().add(const Duration(days: 1)),
                          onSelected: (DateTime date) {
                            controller.bitisTarihi.value = dateFormat.format(
                              date,
                            );
                          },
                          title: 'scholarship.application_end_date'.tr,
                        ),
                      );
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      width: double.infinity,
                      height: 50,
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
                              controller.bitisTarihi.value,
                              style: TextStyles.textFieldTitle,
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
        20.ph,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                controller.currentSection.value = 1;
              },
              child: Container(
                height: 40,
                width: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('common.back'.tr, style: TextStyles.medium15Black),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (controller.basvuruKosullari.value.isEmpty ||
                    controller.basvuruYapilacakYer.value.isEmpty ||
                    controller.baslangicTarihi.value.isEmpty ||
                    controller.bitisTarihi.value.isEmpty ||
                    (controller.basvuruYapilacakYer.value == "Burs Web Site" &&
                        controller.basvuruURL.value.isEmpty)) {
                  AppSnackbar(
                    'common.error'.tr,
                    'common.fill_all_fields'.tr,
                    backgroundColor: Colors.red.withValues(alpha: 0.7),
                  );
                  return;
                }
                controller.currentSection.value = 3;
              },
              child: Container(
                height: 40,
                width: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('common.continue'.tr,
                    style: TextStyles.medium15white),
              ),
            ),
          ],
        ),
        15.ph,
      ],
    );
  }
}
