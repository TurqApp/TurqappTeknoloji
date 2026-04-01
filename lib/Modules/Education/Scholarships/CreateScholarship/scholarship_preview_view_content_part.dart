part of 'scholarship_preview_view.dart';

extension ScholarshipPreviewViewContentPart on ScholarshipPreviewView {
  Widget _buildPage({
    required BuildContext context,
    required CreateScholarshipController controller,
    required CarouselSliderController carouselController,
    required ScrollController scrollController,
    required RxInt currentIndex,
    required double logoSize,
  }) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'scholarship.preview_title'.tr),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVisualSection(
                        context: context,
                        controller: controller,
                        carouselController: carouselController,
                        currentIndex: currentIndex,
                        logoSize: logoSize,
                      ),
                      16.ph,
                      _buildInfoSection(
                        title: 'scholarship.basic_info'.tr,
                        children: [
                          _buildInfoRow(
                            'scholarship.title_label'.tr,
                            controller.baslik.value,
                          ),
                          _buildInfoRow(
                            'scholarship.provider_label'.tr,
                            controller.bursVeren.value,
                          ),
                          _buildInfoRow(
                            'scholarship.website_label'.tr,
                            controller.website.value,
                          ),
                          _buildInfoRow(
                            'common.description'.tr,
                            controller.aciklama.value,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        title: 'scholarship.application_info'.tr,
                        children: [
                          _buildInfoRow(
                            'scholarship.conditions_label'.tr,
                            controller.localizedConditionsText(
                              controller.basvuruKosullari.value,
                            ),
                          ),
                          _buildInfoRow(
                            'scholarship.application_website_label'.tr,
                            controller.basvuruURL.value,
                          ),
                          _buildInfoRow(
                            'scholarship.application_place_label'.tr,
                            controller.applicationPlaceDisplayLabel(
                              controller.basvuruYapilacakYer.value,
                            ),
                          ),
                          _buildInfoRow(
                            'scholarship.application_start_date'.tr,
                            controller.baslangicTarihi.value,
                          ),
                          _buildInfoRow(
                            'scholarship.application_end_date'.tr,
                            controller.bitisTarihi.value,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        title: 'scholarship.extra_info'.tr,
                        elevated: true,
                        children: [
                          _buildInfoRow(
                            'scholarship.amount_label'.tr,
                            '${controller.tutar.value} ₺',
                          ),
                          _buildInfoRow(
                            'scholarship.student_count_label'.tr,
                            controller.ogrenciSayisi.value,
                          ),
                          _buildInfoRow(
                            'scholarship.repayable_label'.tr,
                            controller.scholarshipRepayableLabel(
                              controller.geriOdemeli.value,
                            ),
                          ),
                          _buildInfoRow(
                            'scholarship.duplicate_status_label'.tr,
                            controller.scholarshipDuplicateStatusLabel(
                              controller.mukerrerDurumu.value,
                            ),
                          ),
                          _buildInfoRow(
                            'scholarship.education_audience_label'.tr,
                            controller.scholarshipEducationAudienceLabel(
                              controller.egitimKitlesi.value,
                            ),
                          ),
                          _buildInfoRow(
                            'scholarship.target_audience_label'.tr,
                            controller.scholarshipTargetAudienceLabel(
                              controller.hedefKitle.value,
                            ),
                          ),
                          _buildInfoRow(
                            'scholarship.country_label'.tr,
                            controller.scholarshipCountryLabel(
                              controller.ulke.value,
                            ),
                          ),
                          _buildInfoRow(
                            'scholarship.cities_label'.tr,
                            controller.sehirler.join(', '),
                          ),
                          _buildInfoRow(
                            'scholarship.universities_label'.tr,
                            controller.universiteler.join(', '),
                          ),
                          _buildInfoRow(
                            'scholarship.required_docs_label'.tr,
                            controller.localizedDocumentsText(
                              controller.belgeler,
                              separator: ', ',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildActionsRow(
                        controller: controller,
                        carouselController: carouselController,
                        scrollController: scrollController,
                        currentIndex: currentIndex,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Expanded(child: Divider()),
        Text('  $title  ', style: TextStyles.bold20Black),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
    bool elevated = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          12.ph,
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionsRow({
    required CreateScholarshipController controller,
    required CarouselSliderController carouselController,
    required ScrollController scrollController,
    required RxInt currentIndex,
  }) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'common.back'.tr,
                style: TextStyles.textFieldTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              if (controller.isLoading.value) return;
              if (currentIndex.value != 0) {
                await carouselController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              if (scrollController.hasClients &&
                  scrollController.offset > 0) {
                await scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              await WidgetsBinding.instance.endOfFrame;
              if (controller.isEditing.value) {
                await controller.updateScholarship();
              } else {
                await controller.saveScholarship();
              }
            },
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.textBlack,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Obx(() {
                return controller.isLoading.value
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Text(
                        controller.isEditing.value
                            ? 'common.update'.tr
                            : 'common.share'.tr,
                        style: TextStyles.medium15white.copyWith(fontSize: 16),
                      );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyles.textFieldTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textBlack,
            ),
          ),
          4.ph,
          Text(
            value.isEmpty ? 'common.unspecified'.tr : value,
            style: TextStyles.textFieldTitle.copyWith(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
