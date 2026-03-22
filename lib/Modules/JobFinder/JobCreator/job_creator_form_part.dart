part of 'job_creator.dart';

extension _JobCreatorFormPart on _JobCreatorState {
  Future<void> _submit() async {
    if (controller.isSubmitting.value) return;
    controller.isSubmitting.value = true;
    try {
      if (controller.croppedImage.value == null &&
          (widget.existingJob?.logo.isEmpty ?? true)) {
        AppSnackbar(
          'pasaj.job_finder.create.missing_field'.tr,
          'pasaj.job_finder.create.logo_required'.tr,
        );
        return;
      }
      if (controller.brand.text.trim().isEmpty) {
        AppSnackbar(
          'pasaj.job_finder.create.missing_field'.tr,
          'pasaj.job_finder.create.company_required'.tr,
        );
        return;
      }
      if (controller.sehir.value.isEmpty || controller.ilce.value.isEmpty) {
        AppSnackbar(
          'pasaj.job_finder.create.missing_field'.tr,
          'pasaj.job_finder.create.city_district_required'.tr,
        );
        return;
      }
      if (controller.adres.value.isEmpty && controller.lat.value == 0) {
        AppSnackbar(
          'pasaj.job_finder.create.missing_field'.tr,
          'pasaj.job_finder.create.address_required'.tr,
        );
        return;
      }
      if (controller.selectedCalismaTuruList.isEmpty) {
        AppSnackbar(
          'pasaj.job_finder.create.missing_field'.tr,
          'pasaj.job_finder.create.work_type_required'.tr,
        );
        return;
      }
      if (controller.meslek.value.isEmpty) {
        AppSnackbar(
          'pasaj.job_finder.create.missing_field'.tr,
          'pasaj.job_finder.create.profession_required'.tr,
        );
        return;
      }
      if (controller.isTanimi.text.trim().isEmpty) {
        AppSnackbar(
          'pasaj.job_finder.create.missing_field'.tr,
          'pasaj.job_finder.create.description_required'.tr,
        );
        return;
      }
      if (controller.selectedYanHaklar.isEmpty) {
        AppSnackbar(
          'pasaj.job_finder.create.missing_field'.tr,
          'pasaj.job_finder.create.benefits_required'.tr,
        );
        return;
      }
      if (controller.maasOpen.value && controller.maas1.text.trim().isEmpty) {
        AppSnackbar(
          'pasaj.job_finder.create.missing_field'.tr,
          'pasaj.job_finder.create.min_salary_required'.tr,
        );
        return;
      }
      if (controller.maasOpen.value && controller.maas2.text.trim().isEmpty) {
        AppSnackbar(
          'pasaj.job_finder.create.missing_field'.tr,
          'pasaj.job_finder.create.max_salary_required'.tr,
        );
        return;
      }
      if (controller.maasOpen.value &&
          controller.parseMoneyInput(controller.maas2.text) <
              controller.parseMoneyInput(controller.maas1.text)) {
        AppSnackbar(
          'common.error'.tr,
          'pasaj.job_finder.create.invalid_salary_range'.tr,
        );
        return;
      }
      await controller.setData();
    } finally {
      if (controller.isSubmitting.value) {
        controller.isSubmitting.value = false;
      }
    }
  }
}
