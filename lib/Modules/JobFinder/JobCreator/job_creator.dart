import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Utils/phone_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/job_model.dart';

import 'job_creator_controller.dart';

part 'job_creator_form_part.dart';
part 'job_creator_ui_part.dart';

class JobCreator extends StatefulWidget {
  const JobCreator({super.key, this.existingJob});

  final JobModel? existingJob;

  @override
  State<JobCreator> createState() => _JobCreatorState();
}

class _JobCreatorState extends State<JobCreator> {
  late final String _tag;
  late final JobCreatorController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _tag =
        'job_creator_${widget.existingJob?.docID ?? 'new'}_${identityHashCode(this)}';
    _ownsController = JobCreatorController.maybeFind(tag: _tag) == null;
    controller = JobCreatorController.ensure(
      existingJob: widget.existingJob,
      tag: _tag,
    );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(JobCreatorController.maybeFind(tag: _tag), controller)) {
      Get.delete<JobCreatorController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle(
          widget.existingJob == null
              ? 'pasaj.job_finder.create_add_title'.tr
              : 'pasaj.job_finder.create_edit_title'.tr,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
            children: [
              _buildLogoPicker(),
              const SizedBox(height: 18),
              _sectionTitle('pasaj.job_finder.create.basic_info'.tr),
              const SizedBox(height: 8),
              TextField(
                controller: controller.brand,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(150),
                ],
                decoration:
                    _inputDecoration('pasaj.job_finder.create.company_name'.tr),
              ),
              const SizedBox(height: 18),
              _sectionTitle('pasaj.job_finder.create.location'.tr),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _selectionField(
                      label: controller.sehir.value.isEmpty
                          ? 'common.city'.tr
                          : controller.sehir.value,
                      onTap: controller.showSehirSelect,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _selectionField(
                      label: controller.ilce.value.isEmpty
                          ? 'common.district'.tr
                          : controller.ilce.value,
                      onTap: controller.showIlceSelect,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _sectionTitle('pasaj.job_finder.create.job_desc'.tr),
              const SizedBox(height: 8),
              TextField(
                controller: controller.ilanBasligi,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(100),
                ],
                decoration: _inputDecoration(
                    'pasaj.job_finder.create.listing_title'.tr),
              ),
              const SizedBox(height: 8),
              _selectionField(
                label: controller.selectedCalismaTuruList.isEmpty
                    ? 'pasaj.job_finder.create.work_type'.tr
                    : controller
                        .localizedWorkTypes(controller.selectedCalismaTuruList),
                onTap: controller.selectCalismaTuru,
              ),
              const SizedBox(height: 8),
              _selectionField(
                label: controller.selectedCalismaGunleri.isEmpty
                    ? 'pasaj.job_finder.create.work_days'.tr
                    : controller
                        .localizedWorkDays(controller.selectedCalismaGunleri),
                onTap: controller.selectCalismaGunleri,
              ),
              const SizedBox(height: 8),
              _fieldLabel('pasaj.job_finder.create.work_hours'.tr),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.calismaSaatiBaslangic,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _TimeTextInputFormatter(),
                      ],
                      decoration:
                          _inputDecoration('pasaj.job_finder.create.start'.tr),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller.calismaSaatiBitis,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _TimeTextInputFormatter(),
                      ],
                      decoration:
                          _inputDecoration('pasaj.job_finder.create.end'.tr),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _selectionField(
                label: controller.meslek.value.isEmpty
                    ? 'pasaj.job_finder.create.profession'.tr
                    : controller.meslek.value,
                onTap: controller.showMeslekSelector,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.isTanimi,
                minLines: 4,
                maxLines: 8,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(2000),
                ],
                decoration:
                    _inputDecoration('pasaj.job_finder.create.job_desc'.tr),
              ),
              const SizedBox(height: 8),
              _selectionField(
                label: controller.selectedYanHaklar.isEmpty
                    ? 'pasaj.job_finder.create.benefits'.tr
                    : controller
                        .localizedBenefits(controller.selectedYanHaklar),
                onTap: () => controller.selectYanHaklar(context),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'pasaj.job_finder.create.personnel_count'.tr,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 96,
                    child: TextField(
                      controller: controller.pozisyonSayisi,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      textAlign: TextAlign.center,
                      decoration: _inputDecoration('1'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    controller.maasOpen.value = !controller.maasOpen.value,
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x22000000)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'pasaj.job_finder.create.salary_range'.tr,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black),
                          color: controller.maasOpen.value
                              ? Colors.black
                              : Colors.transparent,
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.maasOpen.value) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.maas1,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _ThousandsTextInputFormatter(),
                        ],
                        decoration: _inputDecoration(
                          'pasaj.job_finder.create.min_salary'.tr,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller.maas2,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _ThousandsTextInputFormatter(),
                        ],
                        decoration: _inputDecoration(
                          'pasaj.job_finder.create.max_salary'.tr,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isSubmitting.value ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.existingJob == null
                              ? 'common.publish'.tr
                              : 'common.update'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'MontserratBold',
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

class _TimeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = phoneDigitsOnly(newValue.text);
    final clipped = digits.length > 4 ? digits.substring(0, 4) : digits;

    if (clipped.length >= 2) {
      final hour = int.tryParse(clipped.substring(0, 2)) ?? -1;
      if (hour < 0 || hour > 23) {
        return oldValue;
      }
    }

    if (clipped.length >= 3) {
      final minuteTens = int.tryParse(clipped.substring(2, 3)) ?? -1;
      if (minuteTens < 0 || minuteTens > 5) {
        return oldValue;
      }
    }

    if (clipped.length == 4) {
      final minute = int.tryParse(clipped.substring(2, 4)) ?? -1;
      if (minute < 0 || minute > 59) {
        return oldValue;
      }
    }

    String formatted;
    if (clipped.length <= 2) {
      formatted = clipped;
    } else {
      formatted = '${clipped.substring(0, 2)}:${clipped.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ThousandsTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = phoneDigitsOnly(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final reversed = digits.split('').reversed.join();
    final chunks = <String>[];
    for (var i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    final formatted = chunks
        .map((chunk) => chunk.split('').reversed.join())
        .toList()
        .reversed
        .join('.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
