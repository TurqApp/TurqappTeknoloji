part of 'create_scholarship_view.dart';

extension CreateScholarshipBasicPart on CreateScholarshipView {
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
          text: controller.isEditing.value ? "Burs Düzenle" : "Burs Oluştur",
        ),
        Text(
          "Temel Bilgiler",
          style: TextStyles.textFieldTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        16.ph,
        Text("Burs Başlığı", style: TextStyles.textFieldTitle),
        4.ph,
        Container(
          alignment: Alignment.center,
          decoration: containerDecoration,
          child: TextFormField(
            cursorColor: Colors.black,
            textCapitalization: TextCapitalization.characters,
            decoration: inputDecoration.copyWith(hintText: "Burs Başlığı"),
            controller: controller.baslikController,
            onChanged: (value) => controller.baslik.value = value,
          ),
        ),
        16.ph,
        Text("Burs Veren", style: TextStyles.textFieldTitle),
        4.ph,
        Container(
          alignment: Alignment.center,
          decoration: containerDecoration,
          child: TextFormField(
            maxLength: 44,
            cursorColor: Colors.black,
            textCapitalization: TextCapitalization.characters,
            decoration: inputDecoration.copyWith(hintText: "Burs Veren"),
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
        Text("Web Sitesi", style: TextStyles.textFieldTitle),
        4.ph,
        Container(
          alignment: Alignment.center,
          decoration: containerDecoration,
          child: TextFormField(
            cursorColor: Colors.black,
            decoration: inputDecoration.copyWith(hintText: "Web Sitesi"),
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
        Text("Açıklama", style: TextStyles.textFieldTitle),
        4.ph,
        Container(
          decoration: containerDecoration,
          child: TextFormField(
            maxLength: 1000,
            minLines: 3,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: inputDecoration.copyWith(hintText: "Açıklama"),
            controller: controller.aciklamaController,
            onChanged: (value) => controller.aciklama.value = value,
          ),
        ),
        4.ph,
        Text(
          "(Burs ilanına ilişkin temel bilgilere bu alanda yer verilebilir. Başvuru koşulları diğer ekranda değerlendirilecektir.)",
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
                child: Text('Geri', style: TextStyles.medium15Black),
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
                    'Hata',
                    'Lütfen tüm alanları doldurunuz.',
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
                child: Text('İleri', style: TextStyles.medium15white),
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
                Text('Temel Bilgiler', style: TextStyles.headerTextStyle),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Başvuru Koşulları", style: TextStyles.textFieldTitle),
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
                    title: "Başvuru Koşulları",
                    items: controller.bursKosullari,
                  ),
                );
              },
              child: Text(
                "Listeden Seç",
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
            decoration: inputDecoration.copyWith(hintText: "Başvuru Koşulları"),
            onChanged: (value) => controller.basvuruKosullari.value = value,
          ),
        ),
        16.ph,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Gerekli Belgeler", style: TextStyles.textFieldTitle),
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
                    title: "Gerekli Belgeler",
                    items: controller.gerekliBelgeler,
                  ),
                );
              },
              child: Text(
                "Listeden Seç",
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
            decoration: inputDecoration.copyWith(hintText: "Gerekli Belgeler"),
            onChanged: (value) {
              controller.belgeler.value = value
                  .split('\n')
                  .where((item) => item.trim().isNotEmpty)
                  .toList();
            },
          ),
        ),
        16.ph,
        Text("Burs Verilecek Aylar", style: TextStyles.textFieldTitle),
        4.ph,
        Container(
          decoration: containerDecoration,
          child: Obx(
            () => TextFormField(
              readOnly: true,
              controller: controller.aylarController
                ..text = controller.aylarText.value.isEmpty
                    ? "Burs Verilecek Aylar"
                    : controller.aylarText.value,
              cursorColor: Colors.black,
              textAlignVertical: TextAlignVertical.center,
              decoration: inputDecoration.copyWith(
                hintText: "Burs Verilecek Aylar",
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
                    title: "Burs Verilecek Aylar",
                    items: controller.bursVerilecekAylar,
                  ),
                );
              },
            ),
          ),
        ),
        16.ph,
        Text("Başvuru Yapılacak Yer", style: TextStyles.textFieldTitle),
        4.ph,
        Container(
          decoration: containerDecoration,
          child: TextFormField(
            readOnly: true,
            controller: controller.basvuruYapilacakYerController,
            cursorColor: Colors.black,
            textAlignVertical: TextAlignVertical.center,
            decoration: inputDecoration.copyWith(
              hintText: "Başvuru Yapılacak Yer",
              suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 20),
            ),
            onTap: () {
              AppBottomSheet.show(
                context: Get.context!,
                items: ["TurqApp", "Burs Web Site"],
                title: "Başvuru Yapılacak Yer",
                selectedItem: controller.basvuruYapilacakYer.value,
                onSelect: (value) {
                  controller.basvuruYapilacakYer.value = value;
                  controller.basvuruYapilacakYerController.text = value;
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
                Text("Burs Web Site", style: TextStyles.textFieldTitle),
                4.ph,
                Container(
                  alignment: Alignment.center,
                  decoration: containerDecoration,
                  child: TextFormField(
                    cursorColor: Colors.black,
                    decoration: inputDecoration.copyWith(
                      hintText: "Burs Web Site",
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
                    "Burs Başvuru Tarihleri",
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
                          title: 'Burs Başvuru Başlangıç Tarihi',
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
                          title: 'Burs Başvuru Bitiş Tarihi',
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
                child: Text('Geri', style: TextStyles.medium15Black),
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
                    'Hata',
                    'Lütfen tüm alanları doldurunuz.',
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
                child: Text('İleri', style: TextStyles.medium15white),
              ),
            ),
          ],
        ),
        15.ph,
      ],
    );
  }
}
