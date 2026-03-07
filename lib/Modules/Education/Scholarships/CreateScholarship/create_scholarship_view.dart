import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/future_date_picker_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/multiple_choice_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/multiple_choice_bottom_sheet2.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_view.dart';
import 'dart:io';
import 'package:turqappv2/Utils/empty_padding.dart';

class CreateScholarshipView extends StatelessWidget {
  const CreateScholarshipView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateScholarshipController());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Obx(
              () => controller.currentSection.value == 1
                  ? buildTemelBilgiler(context, controller)
                  : controller.currentSection.value == 2
                      ? buildBasvuruBilgileri(context, controller)
                      : controller.currentSection.value == 3
                          ? buildEkBilgiler(context, controller)
                          : buildGorsel(context, controller),
            ),
          ),
        ),
      ),
    );
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

  Widget buildGorsel(
    BuildContext context,
    CreateScholarshipController controller,
  ) {
    final containerDecoration = BoxDecoration(
      color: Colors.grey.withAlpha(20),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: GestureDetector(
            onTap: () => controller.currentSection.value = 3,
            child: Row(
              children: [
                Icon(CupertinoIcons.arrow_left, color: Colors.black),
                SizedBox(width: 12),
                Text('Ek Bilgiler', style: TextStyles.headerTextStyle),
              ],
            ),
          ),
        ),
        const Text(
          "Görsel Bilgiler",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        16.ph,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Logo Seç", style: TextStyles.textFieldTitle),
                  4.ph,
                  GestureDetector(
                    onTap: () async {
                      final pickedFile =
                          await AppImagePickerService.pickSingleImage(context);
                      if (pickedFile != null) {
                        // Copy the picked file to a persistent location
                        final tempDir = await getTemporaryDirectory();
                        final newPath =
                            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
                        final newFile = await pickedFile.copy(newPath);

                        if (!await newFile.exists()) {
                          AppSnackbar('Hata', 'Dosya kopyalanamadı.');
                          return;
                        }

                        final r =
                            await OptimizedNSFWService.checkImage(newFile);
                        if (r.isNSFW) {
                          controller.logoPath.value = '';
                          controller.logo.value = '';
                          AppSnackbar("Yükleme Başarısız!",
                              "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
                              backgroundColor:
                                  Colors.red.withValues(alpha: 0.7));
                        } else {
                          controller.logoPath.value = newFile.path;
                          controller.logo.value = newFile.path;
                        }
                      }
                    },
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        decoration: containerDecoration,
                        child: Obx(
                          () => controller.logo.value.isEmpty
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Logo Seçin"),
                                    SizedBox(height: 8),
                                    Icon(
                                      CupertinoIcons.photo_on_rectangle,
                                      size: 28,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                      child: controller.logo.value
                                              .startsWith('http')
                                          ? Image.network(
                                              controller.logo.value,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Icon(Icons.error),
                                            )
                                          : Image.file(
                                              File(controller.logo.value),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          controller.logoPath.value = '';
                                          controller.logo.value = '';
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.6),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
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
                ],
              ),
            ),
            8.pw,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tasarımınız (Opsiyonel)",
                    style: TextStyles.textFieldTitle,
                  ),
                  4.ph,
                  GestureDetector(
                    onTap: () async {
                      final pickedFile =
                          await AppImagePickerService.pickSingleImage(context);
                      if (pickedFile != null) {
                        // Copy the picked file to a persistent location
                        final tempDir = await getTemporaryDirectory();
                        final newPath =
                            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
                        final newFile = await pickedFile.copy(newPath);

                        if (!await newFile.exists()) {
                          AppSnackbar('Hata', 'Dosya kopyalanamadı.');
                          return;
                        }

                        final r =
                            await OptimizedNSFWService.checkImage(newFile);
                        if (r.isNSFW) {
                          controller.customImagePath.value = '';
                          AppSnackbar("Yükleme Başarısız!",
                              "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
                              backgroundColor:
                                  Colors.red.withValues(alpha: 0.7));
                        } else {
                          controller.customImagePath.value = newFile.path;
                        }
                      }
                    },
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        width: double.infinity,
                        decoration: containerDecoration,
                        child: Obx(
                          () => controller.customImagePath.value.isEmpty
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Görsel Seçin"),
                                    SizedBox(height: 8),
                                    Icon(
                                      CupertinoIcons.photo,
                                      size: 28,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                      child: controller.customImagePath.value
                                              .startsWith('http')
                                          ? Image.network(
                                              controller.customImagePath.value,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Icon(Icons.error),
                                            )
                                          : Image.file(
                                              File(controller
                                                  .customImagePath.value),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          controller.customImagePath.value = '';
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.6),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
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
                ],
              ),
            ),
          ],
        ),
        16.ph,
        Text("Şablon Seç", style: TextStyles.textFieldTitle),
        4.ph,
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 4 / 3,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: List.generate(12, (index) {
            return GestureDetector(
              onTap: () {
                controller.selectedTemplateIndex.value = index;
              },
              child: Obx(
                () => Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: controller.selectedTemplateIndex.value == index
                          ? Colors.yellow
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/bursSablonlar/${index + 1}.webp',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        preview(context, controller),
      ],
    );
  }

  Widget preview(BuildContext context, CreateScholarshipController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              controller.currentSection.value = 3;
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
              if (controller.logo.value.isEmpty ||
                  controller.selectedTemplateIndex.value == -1) {
                AppSnackbar(
                  'Hata',
                  'Lütfen tüm alanları doldurunuz.',
                  backgroundColor: Colors.red.withValues(alpha: 0.7),
                );
                return;
              }
              controller.goToPreview();
            },
            child: Container(
              height: 40,
              width: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Önizleme', style: TextStyles.medium15white),
            ),
          ),
        ],
      ),
    );
  }
}
