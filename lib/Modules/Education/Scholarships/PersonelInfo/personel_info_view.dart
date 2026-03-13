import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/date_picker_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Modules/Education/Scholarships/PersonelInfo/personel_info_controller.dart';

class PersonelInfoView extends StatelessWidget {
  PersonelInfoView({super.key});

  final PersonelInfoController controller = Get.put(PersonelInfoController());
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          controller.resetToOriginal();
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BackButtons(text: "Kişisel Bilgiler"),
                  PullDownButton(
                    itemBuilder: (context) => [
                      PullDownMenuItem(
                        title: 'Bilgilerimi Sıfırla',
                        icon: CupertinoIcons.restart,
                        onTap: () {
                          noYesAlert(
                            title: "Emin misiniz?",
                            message:
                                "Kişisel bilgileriniz sıfırlanacak. Bu işlem geri alınamaz.",
                            cancelText: "İptal",
                            yesText: "Sıfırla",
                            onYesPressed: () async {
                              // 1) Controller reset
                              controller.resetToOriginal();
                              // 2) Firestore güncellemesi
                              await _userRepository.updateUserFields(
                                FirebaseAuth.instance.currentUser?.uid ?? '',
                                {
                                ...scopedUserUpdate(
                                  scope: 'family',
                                  values: {"engelliRaporu": "Yok"},
                                ),
                                ...scopedUserUpdate(
                                  scope: 'profile',
                                  values: {
                                    "tc": "",
                                    "medeniHal": "Bekar",
                                    "ulke": "Türkiye",
                                    "nufusSehir": "",
                                    "nufusIlce": "",
                                    "cinsiyet": "Seçim Yap",
                                    "calismaDurumu": "Çalışmıyor",
                                    "dogumTarihi": "",
                                  },
                                ),
                              },
                              );
                              // 3) Yeni veriyi çek
                              await controller.fetchData();
                              // 4) Başarılı snackbar
                              AppSnackbar(
                                "Başarılı",
                                "Kişisel Bilgileriniz sıfırlandı.",
                              );
                            },
                          );
                        },
                      ),
                    ],
                    buttonBuilder: (context, showMenu) => IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: showMenu,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Obx(
                  () => controller.isLoading.value
                      ? const Center(child: CupertinoActivityIndicator())
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Nüfusa Kayıtlı İl - İlçe",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownField(
                                  config: controller.fieldConfigs[0], // ulke
                                  controller: controller,
                                ),
                                if (controller.county.value == "Türkiye" &&
                                    controller.county.value.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: DropdownField(
                                          config: FieldConfig(
                                            label: "İl",
                                            title: "İl Seç",
                                            value: controller.city,
                                            items: controller.sehirler,
                                            onSelect: (val) =>
                                                controller.updateCity(val),
                                            isSearchable: true,
                                          ),
                                          controller: controller,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: DropdownField(
                                          config: FieldConfig(
                                            label: "İlçe",
                                            title: "İlçe Seç",
                                            value: controller.town,
                                            items:
                                                controller.sehirlerVeIlcelerData
                                                    .where(
                                                      (e) =>
                                                          e.il ==
                                                          controller.city.value,
                                                    )
                                                    .map((e) => e.ilce)
                                                    .toList(),
                                            onSelect: (val) =>
                                                controller.updateTown(val),
                                            isSearchable: true,
                                          ),
                                          controller: controller,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Text(
                                  "Doğum Tarihi",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    await showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return DatePickerBottomSheet(
                                          initialDate:
                                              controller.selectedDate.value,
                                          onSelected: (DateTime date) {
                                            controller.selectedDate.value =
                                                date;
                                          },
                                          title: 'Doğum Tarihiniz',
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Obx(
                                          () => Text(
                                            controller.selectedDate.value ==
                                                    null
                                                ? "Doğum Tarihi Seç"
                                                : DateFormat(
                                                    "dd.MM.yyyy",
                                                    "tr_TR",
                                                  ).format(
                                                    controller
                                                        .selectedDate.value!,
                                                  ),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: controller
                                                          .selectedDate.value ==
                                                      null
                                                  ? Colors.grey
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                        const Icon(CupertinoIcons.calendar),
                                      ],
                                    ),
                                  ),
                                ),
                                ...controller.fieldConfigs.sublist(1).map(
                                      (config) => Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          DropdownField(
                                            config: config,
                                            controller: controller,
                                          ),
                                        ],
                                      ),
                                    ),
                                const SizedBox(
                                  height: 20,
                                ), // Padding for bottom
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(
                  () => GestureDetector(
                    onTap:
                        controller.isSaving.value ? null : controller.saveData,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(12),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: controller.isSaving.value
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Kaydet",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DropdownField extends StatelessWidget {
  final FieldConfig config;
  final PersonelInfoController controller;

  const DropdownField({
    super.key,
    required this.config,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config.label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratMedium",
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => controller.toggleDropdown(context, config),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    config.value.value.isEmpty
                        ? "${config.label} Seç"
                        : config.value.value,
                    style: TextStyle(
                      fontSize: 16,
                      color: config.value.value.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                Icon(CupertinoIcons.chevron_down, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
