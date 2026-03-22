part of 'family_info_view.dart';

extension _FamilyInfoViewSectionsPart on _FamilyInfoViewState {
  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFatherSection(),
        const Divider(),
        _buildMotherSection(),
        const Divider(),
        _buildGeneralFamilySection(),
      ],
    );
  }

  Widget _buildFatherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Obx(
          () => controller.isFatherAlive
              ? _buildParentDetailsSection(
                  fullNameTitle: 'family_info.father_name_surname'.tr,
                  nameController: controller.fatherName.value,
                  nameHint: 'scholarship.applicant.father_name'.tr,
                  surnameController: controller.fatherSurname.value,
                  surnameHint: 'scholarship.applicant.father_surname'.tr,
                  jobTitle: 'scholarship.applicant.father_job'.tr,
                  jobValue: controller.fatherJob.value,
                  onJobTap: () => controller.showBottomSheet(
                    'scholarship.applicant.father_job'.tr,
                    controller.fatherJob,
                    allJobs,
                  ),
                  salaryTitle: 'family_info.father_salary'.tr,
                  salaryController: controller.fatherSalary.value,
                  phoneTitle: 'family_info.father_phone'.tr,
                  phoneController: controller.fatherPhoneNumber.value,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildMotherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Obx(
          () => controller.isMotherAlive
              ? _buildParentDetailsSection(
                  fullNameTitle: 'family_info.mother_name_surname'.tr,
                  nameController: controller.motherName.value,
                  nameHint: 'scholarship.applicant.mother_name'.tr,
                  surnameController: controller.motherSurname.value,
                  surnameHint: 'scholarship.applicant.mother_surname'.tr,
                  jobTitle: 'scholarship.applicant.mother_job'.tr,
                  jobValue: controller.motherJob.value,
                  onJobTap: () => controller.showBottomSheet(
                    'scholarship.applicant.mother_job'.tr,
                    controller.motherJob,
                    allJobs,
                  ),
                  salaryTitle: 'family_info.mother_salary'.tr,
                  salaryController: controller.motherSalary.value,
                  phoneTitle: 'family_info.mother_phone'.tr,
                  phoneController: controller.motherPhoneNumber.value,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildParentDetailsSection({
    required String fullNameTitle,
    required TextEditingController nameController,
    required String nameHint,
    required TextEditingController surnameController,
    required String surnameHint,
    required String jobTitle,
    required String jobValue,
    required VoidCallback onJobTap,
    required String salaryTitle,
    required TextEditingController salaryController,
    required String phoneTitle,
    required TextEditingController phoneController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullNameTitle,
          style: TextStyles.textFieldTitle,
        ),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: nameController,
                hintText: nameHint,
                formatters: [
                  LengthLimitingTextInputFormatter(26),
                  CapitalizeInputFormatter(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: surnameController,
                hintText: surnameHint,
                formatters: [
                  LengthLimitingTextInputFormatter(26),
                  CapitalizeInputFormatter(),
                ],
              ),
            ),
          ],
        ),
        12.ph,
        Text(
          jobTitle,
          style: TextStyles.textFieldTitle,
        ),
        _buildDropdownField(
          title: jobTitle,
          value: jobValue.isEmpty
              ? 'family_info.select_job'.tr
              : controller.localizedSelection(jobValue),
          hintText: 'family_info.select_job'.tr,
          onTap: onJobTap,
        ),
        12.ph,
        Text(
          salaryTitle,
          style: TextStyles.textFieldTitle,
        ),
        _buildTextField(
          controller: salaryController,
          hintText: 'family_info.salary_hint'.tr,
          keyboardType: TextInputType.number,
          formatters: [
            LengthLimitingTextInputFormatter(10),
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            MaxValueTextInputFormatter(199999),
          ],
          suffixText: "(₺)",
        ),
        12.ph,
        Text(
          phoneTitle,
          style: TextStyles.textFieldTitle,
        ),
        _buildTextField(
          controller: phoneController,
          hintText: 'common.phone'.tr,
          prefixText: "(+90) ",
          keyboardType: TextInputType.phone,
          formatters: [
            LengthLimitingTextInputFormatter(10),
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ],
        ),
        12.ph,
      ],
    );
  }

  Widget _buildGeneralFamilySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'family_info.family_size'.tr,
          style: TextStyles.textFieldTitle,
        ),
        _buildTextField(
          controller: controller.totalLiving.value,
          hintText: 'family_info.family_size_hint'.tr,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          formatters: [
            LengthLimitingTextInputFormatter(2),
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
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
              : controller.localizedSelection(controller.evMulkiyeti.value),
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
        _buildResidenceSelectors(),
        20.ph,
        GestureDetector(
          onTap: controller.setData,
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Text(
              'common.save'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResidenceSelectors() {
    return Row(
      children: [
        Expanded(
          child: _buildResidencePicker(
            label: controller.city.value.isEmpty
                ? 'common.select_city'.tr
                : controller.city.value,
            onTap: controller.showIlSec,
          ),
        ),
        if (controller.city.value.isNotEmpty) const SizedBox(width: 12),
        if (controller.city.value.isNotEmpty)
          Expanded(
            child: _buildResidencePicker(
              label: controller.town.value.isNotEmpty
                  ? controller.town.value
                  : 'common.select_district'.tr,
              onTap: controller.showIlcelerSec,
            ),
          ),
      ],
    );
  }

  Widget _buildResidencePicker({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(20),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_down,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
