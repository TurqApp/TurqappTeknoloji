part of 'job_creator.dart';

extension _JobCreatorContentPart on _JobCreatorState {
  Widget _buildScaffold(BuildContext context) {
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
                inputFormatters: const [
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
                inputFormatters: const [
                  LengthLimitingTextInputFormatter(100),
                ],
                decoration: _inputDecoration(
                  'pasaj.job_finder.create.listing_title'.tr,
                ),
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
                inputFormatters: const [
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
                      style: const TextStyle(
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
                      inputFormatters: const [
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
              _buildSalaryToggle(),
              if (controller.maasOpen.value) ...[
                const SizedBox(height: 8),
                _buildSalaryInputs(),
              ],
              const SizedBox(height: 22),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalaryToggle() {
    return GestureDetector(
      onTap: () => controller.maasOpen.value = !controller.maasOpen.value,
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
                style: const TextStyle(
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
    );
  }

  Widget _buildSalaryInputs() {
    return Row(
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
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }
}
