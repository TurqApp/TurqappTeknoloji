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
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Education/Scholarships/PersonelInfo/personel_info_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class PersonelInfoView extends StatefulWidget {
  PersonelInfoView({super.key});

  @override
  State<PersonelInfoView> createState() => _PersonelInfoViewState();
}

class _PersonelInfoViewState extends State<PersonelInfoView> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final PersonelInfoController controller;
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  void initState() {
    super.initState();
    _controllerTag = 'scholarship_personal_${identityHashCode(this)}';
    final existing = PersonelInfoController.maybeFind(tag: _controllerTag);
    _ownsController = existing == null;
    controller = existing ?? PersonelInfoController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          PersonelInfoController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<PersonelInfoController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

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
                  BackButtons(text: 'personal_info.title'.tr),
                  PullDownButton(
                    itemBuilder: (context) => [
                      PullDownMenuItem(
                        title: 'personal_info.reset_menu'.tr,
                        icon: CupertinoIcons.restart,
                        onTap: () {
                          noYesAlert(
                            title: 'personal_info.reset_title'.tr,
                            message: 'personal_info.reset_body'.tr,
                            cancelText: 'common.cancel'.tr,
                            yesText: 'common.reset'.tr,
                            onYesPressed: () async {
                              // 1) Controller reset
                              controller.resetToOriginal();
                              // 2) Firestore güncellemesi
                              await _userRepository.updateUserFields(
                                CurrentUserService.instance.userId,
                                {
                                  ...scopedUserUpdate(
                                    scope: 'family',
                                    values: {
                                      "engelliRaporu": controller.noneValue,
                                    },
                                  ),
                                  ...scopedUserUpdate(
                                    scope: 'profile',
                                    values: {
                                      "tc": "",
                                      "medeniHal": controller.singleValue,
                                      "ulke": controller.turkeyValue,
                                      "nufusSehir": "",
                                      "nufusIlce": "",
                                      "cinsiyet": controller.defaultSelectValue,
                                      "calismaDurumu":
                                          controller.notWorkingValue,
                                      "dogumTarihi": "",
                                    },
                                  ),
                                },
                              );
                              // 3) Yeni veriyi çek
                              await controller.fetchData();
                              // 4) Başarılı snackbar
                              AppSnackbar(
                                'common.success'.tr,
                                'personal_info.reset_success'.tr,
                              );
                            },
                          );
                        },
                      ),
                    ],
                    buttonBuilder: (context, showMenu) => AppHeaderActionButton(
                      onTap: showMenu,
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.black,
                        size: 20,
                      ),
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
                                  'personal_info.registry_info'.tr,
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
                                if (controller.isTurkeySelected &&
                                    controller.county.value.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: DropdownField(
                                          config: FieldConfig(
                                            label: "common.city".tr,
                                            title: "common.select_city".tr,
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
                                            label: "common.district".tr,
                                            title: "common.select_district".tr,
                                            value: controller.town,
                                            items: (() {
                                              final towns = controller
                                                  .sehirlerVeIlcelerData
                                                  .where(
                                                    (e) =>
                                                        e.il ==
                                                        controller.city.value,
                                                  )
                                                  .map((e) => e.ilce)
                                                  .toList();
                                              sortTurkishStrings(towns);
                                              return towns;
                                            })(),
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
                                  'scholarship.applicant.birth_date'.tr,
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
                                          title:
                                              'personal_info.birth_date_title'
                                                  .tr,
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
                                                ? 'personal_info.select_birth_date'
                                                    .tr
                                                : DateFormat(
                                                    "dd.MM.yyyy",
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
                          : Text(
                              'common.save'.tr,
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
          controller.localizedFieldLabel(config.label),
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
                    config.value.value.isEmpty ||
                            config.value.value == controller.defaultSelectValue
                        ? controller.localizedPlaceholder(config.label)
                        : controller.localizedStaticValue(config.value.value),
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
