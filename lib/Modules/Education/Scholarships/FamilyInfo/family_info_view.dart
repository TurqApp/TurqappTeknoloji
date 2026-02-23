import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
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
        Expanded(child: BackButtons(text: "Aile Bilgileri")),
        PullDownButton(
          itemBuilder: (context) => [
            PullDownMenuItem(
              title: 'Aile Bilgilerini Sıfırla',
              onTap: () {
                noYesAlert(
                  title: "Aile Bilgilerini Sıfırla",
                  message:
                      "Tüm aile bilgileriniz silinecektir. Bu işlem geri alınamaz. Emin misiniz?",
                  cancelText: "İptal",
                  yesText: "Sıfırla",
                  onYesPressed: () {
                    controller.resetFamilyInfo();
                  },
                );
              },
              icon: CupertinoIcons.refresh,
            ),
          ],
          buttonBuilder: (context, showMenu) => IconButton(
            onPressed: showMenu,
            icon: Icon(
              AppIcons.ellipsisVertical,
              color: Colors.black,
              size: 24,
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
                                "Baba Hayatta Mı?",
                                style: TextStyles.textFieldTitle,
                              ),
                              _buildDropdownField(
                                title: "Baba Hayatta Mı?",
                                value: controller.fatherLiving.value.isEmpty
                                    ? "Seçiniz"
                                    : controller.fatherLiving.value,
                                hintText: "Seçiniz",
                                onTap: () => controller.showBottomSheet2(
                                  "Baba Hayatta Mı?",
                                  controller.fatherLiving,
                                  controller.living,
                                ),
                              ),
                              12.ph,

                              // BABA BILGILERI - DINAMIK OLARAK GÖSTER
                              Obx(() {
                                if (controller.fatherLiving.value == "Evet") {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Baba Ad - Soyad",
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller:
                                                  controller.fatherName.value,
                                              hintText: "Baba Adı",
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
                                              hintText: "Baba Soyadı",
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
                                        "Baba Mesleği",
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      _buildDropdownField(
                                        title: "Baba Mesleği",
                                        value:
                                            controller.fatherJob.value.isEmpty
                                                ? "Meslek Seç"
                                                : controller.fatherJob.value,
                                        hintText: "Meslek Seç",
                                        onTap: () => controller.showBottomSheet(
                                          "Baba Mesleği",
                                          controller.fatherJob,
                                          allJobs,
                                        ),
                                      ),
                                      12.ph,
                                      Text(
                                        "Baba Net Maaş",
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      _buildTextField(
                                        controller:
                                            controller.fatherSalary.value,
                                        hintText: "Net Maaş",
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
                                        "Baba İletişim Numarası",
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      _buildTextField(
                                        controller:
                                            controller.fatherPhoneNumber.value,
                                        hintText: "Telefon Numarası",
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
                                "Anne Hayatta Mı?",
                                style: TextStyles.textFieldTitle,
                              ),
                              _buildDropdownField(
                                title: "Anne Hayatta",
                                value: controller.motherLiving.value.isEmpty
                                    ? "Seçiniz"
                                    : controller.motherLiving.value,
                                hintText: "Seçiniz",
                                onTap: () => controller.showBottomSheet2(
                                  "Anne Hayatta",
                                  controller.motherLiving,
                                  controller.living,
                                ),
                              ),
                              12.ph,

                              // ANNE BILGILERI - DINAMIK OLARAK GÖSTER
                              Obx(() {
                                if (controller.motherLiving.value == "Evet") {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Anne Ad - Soyad",
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller:
                                                  controller.motherName.value,
                                              hintText: "Anne Adı",
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
                                              hintText: "Anne Soyadı",
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
                                        "Anne Mesleği",
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      _buildDropdownField(
                                        title: "Anne Mesleği",
                                        value:
                                            controller.motherJob.value.isEmpty
                                                ? "Meslek Seç"
                                                : controller.motherJob.value,
                                        hintText: "Meslek Seç",
                                        onTap: () => controller.showBottomSheet(
                                          "Anne Mesleği",
                                          controller.motherJob,
                                          allJobs,
                                        ),
                                      ),
                                      12.ph,
                                      Text(
                                        "Anne Net Maaş",
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      _buildTextField(
                                        controller:
                                            controller.motherSalary.value,
                                        hintText: "Net Maaş",
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
                                        "Anne İletişim Numarası",
                                        style: TextStyles.textFieldTitle,
                                      ),
                                      _buildTextField(
                                        controller:
                                            controller.motherPhoneNumber.value,
                                        hintText: "Telefon Numarası",
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
                                "Aile Sayısı",
                                style: TextStyles.textFieldTitle,
                              ),
                              _buildTextField(
                                controller: controller.totalLiving.value,
                                hintText: "Ailede (Siz Dahil) Yaşayan Sayısı",
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
                                "Ev Mülkiyeti",
                                style: TextStyles.textFieldTitle,
                              ),
                              _buildDropdownField(
                                title: "Ev Mülkiyeti",
                                value: controller.evMulkiyeti.value,
                                hintText: "Seçiniz",
                                onTap: () => controller.showBottomSheet2(
                                  "Ev Mülkiyeti",
                                  controller.evMulkiyeti,
                                  controller.evevMulkiyeti,
                                ),
                              ),
                              24.ph,
                              Text(
                                "İkametgâh Bilgisi",
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
                                                    ? "Şehir Seç"
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
                                                      : "İlçe Seç",
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
                                    "Kaydet",
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
      String capitalized = newValue.text.split(' ').map((word) {
        if (word.isNotEmpty) {
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }
        return '';
      }).join(' ');
      return newValue.copyWith(
        text: capitalized,
        selection: TextSelection.collapsed(offset: capitalized.length),
      );
    }
    return newValue;
  }
}
