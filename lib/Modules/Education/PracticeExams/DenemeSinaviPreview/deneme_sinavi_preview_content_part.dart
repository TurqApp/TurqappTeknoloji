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
                return const Center(child: CupertinoActivityIndicator());
              }
              if (controller.isInitialized.value &&
                  controller.nickname.value.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'practice.user_load_failed_body'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ),
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

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 1,
        child: CachedNetworkImage(
          imageUrl: controller.model.cover,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => Center(
            child: Text(
              'practice.cover_load_failed'.tr,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 15,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF6F7FB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAuthorCard(DenemeSinaviPreviewController controller) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF6F7FB),
      ),
      child: GestureDetector(
        onTap: isCurrentUserId(controller.model.userID)
            ? null
            : () =>
                Get.to(() => SocialProfile(userID: controller.model.userID)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE5E7EB),
              backgroundImage: controller.avatarUrl.value.trim().isNotEmpty
                  ? NetworkImage(controller.avatarUrl.value)
                  : null,
              child: controller.avatarUrl.value.trim().isEmpty
                  ? const Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.black54,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          controller.nickname.value.isEmpty
                              ? 'common.user'.tr
                              : controller.nickname.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                      RozetContent(size: 14, userID: controller.model.userID),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCurrentUserId(controller.model.userID)
                        ? 'practice.owner'.tr
                        : 'social_profile.view_profile'.tr,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
            ),
            if (!isCurrentUserId(controller.model.userID))
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.black45,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessSheet(DenemeSinaviPreviewController controller) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        GestureDetector(
          onTap: () => controller.showSucces.value = false,
          child: Container(color: Colors.black.withValues(alpha: 0.2)),
        ),
        Container(
          height: (Get.height * 0.28).clamp(190.0, 220.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(18),
              topLeft: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'practice.apply_completed_title'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                15.ph,
                Text(
                  'practice.apply_completed_body'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                15.ph,
                GestureDetector(
                  onTap: Get.back,
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Text(
                      'common.ok'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
