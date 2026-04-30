part of 'deneme_sinavi_preview.dart';

extension DenemeSinaviPreviewContentPart on _DenemeSinaviPreviewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenPracticeExamPreview),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: const AppPageTitle(
          'practice.preview_title',
          translate: true,
          fontSize: 20,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: EducationFeedShareIconButton(
              onTap: () => shareService.sharePracticeExam(widget.model),
              size: 36,
              iconSize: 20,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Obx(
              () => AppHeaderActionButton(
                onTap: controller.toggleSaved,
                child: Icon(
                  controller.isSaved.value
                      ? CupertinoIcons.bookmark_fill
                      : CupertinoIcons.bookmark,
                  size: 20,
                  color:
                      controller.isSaved.value ? Colors.orange : Colors.black87,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _pullDownMenu(controller),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Obx(() {
              if (controller.isLoading.value) {
                return const AppStateView.loading();
              }
              if (controller.isInitialized.value &&
                  controller.displayName.value.isEmpty &&
                  controller.nickname.value.isEmpty) {
                return AppStateView.empty(
                  title: 'practice.user_load_failed_body'.tr,
                  icon: Icons.person_off_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.refreshData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                  children: [
                    _buildCover(),
                    const SizedBox(height: 14),
                    Text(
                      controller.model.sinavAdi,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${controller.model.sinavTuru}  •  ${formatTimestamp(controller.model.timeStamp.toInt())}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'common.description'.tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.model.sinavAciklama.isEmpty
                          ? 'practice.no_description'.tr
                          : controller.model.sinavAciklama,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.45,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _infoCard(
                      title: 'practice.exam_info'.tr,
                      children: [
                        _infoRow(
                          'practice.exam_type'.tr,
                          'practice.exam_suffix'
                              .trParams({'type': controller.model.sinavTuru}),
                        ),
                        _infoRow(
                          'practice.exam_datetime'.tr,
                          formatTimestamp(controller.model.timeStamp.toInt()),
                        ),
                        _infoRow(
                          'practice.exam_duration'.tr,
                          'practice.duration_minutes'.trParams(
                              {'minutes': '${controller.model.bitisDk}'}),
                        ),
                        Obx(
                          () => _infoRow(
                            'practice.application_count'.tr,
                            'practice.people_count'.trParams({
                              'count': '${controller.basvuranSayisi.value}',
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Obx(() => _buildAuthorCard(controller)),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => _handlePrimaryAction(controller),
                      child: Obx(
                        () => Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _ctaColor(controller),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _ctaLabel(controller),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              height: 1.5,
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const AdmobKare(
                      key: ValueKey('practice-exam-detail-ad-end'),
                      suggestionPlacementId: 'practice_exam',
                    ),
                  ],
                ),
              );
            }),
            Obx(
              () => controller.showSucces.value
                  ? _buildSuccessSheet(controller)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
