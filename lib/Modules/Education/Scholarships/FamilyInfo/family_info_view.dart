import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/job_categories.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/FamilyInfo/family_info_controller.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class FamilyInfoView extends StatelessWidget {
  FamilyInfoView({super.key});

  final FamilyInfoController controller = Get.put(FamilyInfoController());

  Widget _buildCustomHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: BackButtons(text: 'family_info.title'.tr)),
        PullDownButton(
          itemBuilder: (context) => [
            PullDownMenuItem(
              title: 'family_info.reset_menu'.tr,
              onTap: () {
                noYesAlert(
                  title: 'family_info.reset_title'.tr,
                  message: 'family_info.reset_body'.tr,
                  cancelText: 'common.cancel'.tr,
                  yesText: 'common.reset'.tr,
                  onYesPressed: () {
                    controller.resetFamilyInfo();
                  },
                );
              },
              icon: CupertinoIcons.refresh,
            ),
          ],
          buttonBuilder: (context, showMenu) => AppHeaderActionButton(
            onTap: showMenu,
            child: Icon(
              AppIcons.ellipsisVertical,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomHeader(),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? Center(child: CupertinoActivityIndicator())
                    : SingleChildScrollView(
                        controller: controller.scrollController,
                        physics: ScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // BABA SECTION
                              Text(
                                'scholarship.applicant.father_alive'.tr,
                                style: TextStyles.textFieldTitle,
                              ),
                              _buildDropdownField(
                                title: 'scholarship.applicant.father_alive'.tr,
                                value: controller.fatherLiving.value.isEmpty ||
                                        controller.isFatherUnselected
                                    ? 'common.select'.tr
                                    : controller.localizedSelection(
                                        controller.fatherLiving.value,
                                      ),
                                hintText: 'common.select'.tr,
                                onTap: () => controller.showBottomSheet2(
                                  'scholarship.applicant.father_alive'.tr,
                                  controller.fatherLiving,
                                  controller.living,
                                ),
                              ),
                              12.ph,

                              // BABA BILGILERI - DINAMIK OLARAK GÖSTER
                              Obx(() {
                                if (controller.isFatherAlive) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'family_info.father_name_surname'.tr,
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller:
                                                  controller.fatherName.value,
                                              hintText:
                                                  'scholarship.applicant.father_name'
                                                      .tr,
                                              formatters: [
                                                LengthLimitingTextInputFormatter(
                                                    26),
                                                CapitalizeInputFormatter(),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: _buildTextField(
                                              controller: controller
                                                  .fatherSurname.value,
                                              hintText:
                                                  'scholarship.applicant.father_surname'
                                                      .tr,
                                              formatters: [
                                                LengthLimitingTextInputFormatter(
                                                    26),
                                                CapitalizeInputFormatter(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      12.ph,
                                      Text(
                                        'scholarship.applicant.father_job'.tr,
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      _buildDropdownField(
                                        title:
                                            'scholarship.applicant.father_job'
                                                .tr,
                                        value: controller
                                                .fatherJob.value.isEmpty
                                            ? 'family_info.select_job'.tr
                                            : controller.localizedSelection(
                                                controller.fatherJob.value,
                                              ),
                                        hintText: 'family_info.select_job'.tr,
                                        onTap: () => controller.showBottomSheet(
                                          'scholarship.applicant.father_job'.tr,
                                          controller.fatherJob,
                                          allJobs,
                                        ),
                                      ),
                                      12.ph,
                                      Text(
                                        'family_info.father_salary'.tr,
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      _buildTextField(
                                        controller:
                                            controller.fatherSalary.value,
                                        hintText: 'family_info.salary_hint'.tr,
                                        keyboardType: TextInputType.number,
                                        formatters: [
                                          LengthLimitingTextInputFormatter(10),
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9]'),
                                          ),
                                          MaxValueTextInputFormatter(199999),
                                        ],
                                        suffixText: "(₺)",
                                      ),
                                      12.ph,
                                      Text(
                                        'family_info.father_phone'.tr,
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      _buildTextField(
                                        controller:
                                            controller.fatherPhoneNumber.value,
                                        hintText: 'common.phone'.tr,
                                        prefixText: "(+90) ",
                                        keyboardType: TextInputType.phone,
                                        formatters: [
                                          LengthLimitingTextInputFormatter(10),
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9]'),
                                          ),
                                        ],
                                      ),
                                      12.ph,
                                    ],
                                  );
                                } else {
                                  return SizedBox.shrink();
                                }
                              }),

                              Divider(),

                              // ANNE SECTION
                              Text(
                                'scholarship.applicant.mother_alive'.tr,
                                style: TextStyles.textFieldTitle,
                              ),
                              _buildDropdownField(
                                title: 'scholarship.applicant.mother_alive'.tr,
                                value: controller.motherLiving.value.isEmpty ||
                                        controller.isMotherUnselected
                                    ? 'common.select'.tr
                                    : controller.localizedSelection(
                                        controller.motherLiving.value,
                                      ),
                                hintText: 'common.select'.tr,
                                onTap: () => controller.showBottomSheet2(
                                  'scholarship.applicant.mother_alive'.tr,
                                  controller.motherLiving,
                                  controller.living,
                                ),
                              ),
                              12.ph,

                              // ANNE BILGILERI - DINAMIK OLARAK GÖSTER
                              Obx(() {
                                if (controller.isMotherAlive) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'family_info.mother_name_surname'.tr,
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller:
                                                  controller.motherName.value,
                                              hintText:
                                                  'scholarship.applicant.mother_name'
                                                      .tr,
                                              formatters: [
                                                LengthLimitingTextInputFormatter(
                                                    26),
                                                CapitalizeInputFormatter(),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: _buildTextField(
                                              controller: controller
                                                  .motherSurname.value,
                                              hintText:
                                                  'scholarship.applicant.mother_surname'
                                                      .tr,
                                              formatters: [
                                                LengthLimitingTextInputFormatter(
                                                    26),
                                                CapitalizeInputFormatter(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      12.ph,
                                      Text(
                                        'scholarship.applicant.mother_job'.tr,
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      _buildDropdownField(
                                        title:
                                            'scholarship.applicant.mother_job'
                                                .tr,
                                        value: controller
                                                .motherJob.value.isEmpty
                                            ? 'family_info.select_job'.tr
                                            : controller.localizedSelection(
                                                controller.motherJob.value,
                                              ),
                                        hintText: 'family_info.select_job'.tr,
                                        onTap: () => controller.showBottomSheet(
                                          'scholarship.applicant.mother_job'.tr,
                                          controller.motherJob,
                                          allJobs,
                                        ),
                                      ),
                                      12.ph,
                                      Text(
                                        'family_info.mother_salary'.tr,
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      _buildTextField(
                                        controller:
                                            controller.motherSalary.value,
                                        hintText: 'family_info.salary_hint'.tr,
                                        keyboardType: TextInputType.number,
                                        formatters: [
                                          LengthLimitingTextInputFormatter(10),
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9]'),
                                          ),
                                          MaxValueTextInputFormatter(199999),
                                        ],
                                        suffixText: "(₺)",
                                      ),
                                      12.ph,
                                      Text(
                                        'family_info.mother_phone'.tr,
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      _buildTextField(
                                        controller:
                                            controller.motherPhoneNumber.value,
                                        hintText: 'common.phone'.tr,
                                        prefixText: "(+90) ",
                                        keyboardType: TextInputType.phone,
                                        formatters: [
                                          LengthLimitingTextInputFormatter(10),
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9]'),
                                          ),
                                        ],
                                      ),
                                      12.ph,
                                    ],
                                  );
                                } else {
                                  return SizedBox.shrink();
                                }
                              }),

                              Divider(),

                              // GENEL AILE BILGILERI
                              Text(
                                'family_info.family_size'.tr,
                                style: TextStyles.textFieldTitle,
                              ),
                              _buildTextField(
                                controller: controller.totalLiving.value,
                                hintText: 'family_info.family_size_hint'.tr,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: false),
                                formatters: [
                                  LengthLimitingTextInputFormatter(2),
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]'),
                                  ),
                                  MaxValueTextInputFormatter(15),
                                ],
                              ),
                              24.ph,
                              Text(
                                'scholarship.applicant.home_ownership'.tr,
                                style: TextStyles.textFieldTitle,
                              ),
                              _buildDropdownField(
                                title: 'scholarship.applicant.home_ownership'.tr,
                                value: controller.isHomeOwnershipUnselected
                                    ? 'common.select'.tr
                                    : controller.localizedSelection(
                                        controller.evMulkiyeti.value,
                                      ),
                                hintText: 'common.select'.tr,
                                onTap: () => controller.showBottomSheet2(
                                  'scholarship.applicant.home_ownership'.tr,
                                  controller.evMulkiyeti,
                                  controller.evevMulkiyeti,
                                ),
                              ),
                              24.ph,
                              Text(
                                'family_info.residence_info'.tr,
                                style: TextStyles.textFieldTitle,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: controller.showIlSec,
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.centerLeft,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withAlpha(20),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 15),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                                Text(
                                                  controller.city.value.isEmpty
                                                    ? 'common.select_city'.tr
                                                    : controller.city.value,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                  fontFamily:
                                                      "MontserratMedium",
                                                ),
                                              ),
                                              Icon(
                                                CupertinoIcons.chevron_down,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (controller.city.value.isNotEmpty)
                                    SizedBox(width: 12),
                                  if (controller.city.value.isNotEmpty)
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: controller.showIlcelerSec,
                                        child: Container(
                                          height: 50,
                                          alignment: Alignment.centerLeft,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withAlpha(20),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(12),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 15),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  controller
                                                          .town.value.isNotEmpty
                                                      ? controller.town.value
                                                      : 'common.select_district'
                                                          .tr,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontFamily:
                                                        "MontserratMedium",
                                                  ),
                                                ),
                                                Icon(
                                                  CupertinoIcons.chevron_down,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              20.ph,
                              GestureDetector(
                                onTap: controller.setData,
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'common.save'.tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? prefixText,
    String? suffixText,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            if (prefixText != null)
              Transform.translate(
                offset: Offset(0, -1),
                child: Text(
                  prefixText,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
            Expanded(
              child: TextField(
                cursorColor: Colors.black,
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: formatters,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontFamily: "MontserratMedium",
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
            if (suffixText != null)
              Text(
                suffixText,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String title,
    required String value,
    required String hintText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value.isEmpty || value == hintText ? hintText : value,
                style: TextStyle(
                  color: value.isEmpty || value == hintText
                      ? Colors.grey
                      : Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              Icon(
                CupertinoIcons.chevron_down,
                color: Colors.black45,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MaxValueTextInputFormatter extends TextInputFormatter {
  final int maxValue;

  MaxValueTextInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final int? value = int.tryParse(newValue.text);
    if (value == null || value > maxValue) {
      return oldValue;
    }

    return newValue;
  }
}

class CapitalizeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isNotEmpty) {
      final capitalized = capitalizeWords(newValue.text);
      return newValue.copyWith(
        text: capitalized,
        selection: TextSelection.collapsed(offset: capitalized.length),
      );
    }
    return newValue;
  }
}
