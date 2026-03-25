part of 'scholarship_detail_view.dart';

extension ScholarshipDetailViewBodyPart on ScholarshipDetailView {
  Widget buildContent(BuildContext context) {
    final ScholarshipDetailController controller =
        ScholarshipDetailController.ensure();

    final scholarshipData = Get.arguments as Map<String, dynamic>?;
    if (scholarshipData == null || scholarshipData['model'] == null) {
      return Scaffold(
        key: const ValueKey(IntegrationTestKeys.screenScholarshipDetail),
        body: Center(
          child: Text(
            'scholarship.detail_missing'.tr,
            style: const TextStyle(fontSize: 16, fontFamily: 'MontserratMedium'),
          ),
        ),
      );
    }

    final IndividualScholarshipsModel baseModel =
        scholarshipData['model'] as IndividualScholarshipsModel;
    final String type = kIndividualScholarshipType;
    final String scholarshipDocId =
        (scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '')
            .toString();
    final Map<String, dynamic> userData =
        (scholarshipData['userData'] as Map<String, dynamic>?) ??
            <String, dynamic>{};
    final bool isOwnScholarship = userData['userID']?.toString() ==
        CurrentUserService.instance.effectiveUserId;
    final String userImage = (userData['avatarUrl'] ?? '').toString();
    final String userNick = (userData['displayName'] ??
            userData['username'] ??
            userData['nickname'] ??
            'common.user'.tr)
        .toString();
    final ScrollController detailScrollController = ScrollController();

    return Obx(() {
      final model = controller.resolvedModel.value ?? baseModel;
      final int universityCount = model.universiteler.length;
      if (controller.hiddenUniversityCount.value !=
          (universityCount > 10 ? universityCount - 10 : 0)) {
        controller.hiddenUniversityCount.value =
            universityCount > 10 ? universityCount - 10 : 0;
      }

      final List<String> galleryImages = <String>[
        model.img.trim(),
        model.img2.trim(),
      ].where((image) => image.isNotEmpty).toList(growable: false);
      final String providerName =
          model.bursVeren.trim().isNotEmpty ? model.bursVeren.trim() : userNick;
      final List<String> metaParts = <String>[
        if (providerName.trim().isNotEmpty) providerName.trim(),
        if (model.bitisTarihi.trim().isNotEmpty)
          'education_feed.application_deadline'
              .trParams({'date': model.bitisTarihi.trim()}),
      ];
      final String metaText = metaParts.join('  •  ');
      final String applicationDates = [
        model.baslangicTarihi.trim(),
        model.bitisTarihi.trim(),
      ].where((value) => value.isNotEmpty).join(' - ');
      final String requiredDocs =
          model.belgeler.map((e) => '• $e').join('\n').trim();
      final String awardMonths = model.aylar.map((ay) => '• $ay').join('\n');
      final String otherInfo =
          '• ${'scholarship.duplicate_status_label'.tr}: ${model.mukerrerDurumu.isNotEmpty ? model.mukerrerDurumu : 'common.unspecified'.tr}\n'
          '• ${'scholarship.repayable_label'.tr}: ${model.geriOdemeli.isNotEmpty ? model.geriOdemeli : 'common.unspecified'.tr}';

      return Scaffold(
        key: const ValueKey(IntegrationTestKeys.screenScholarshipDetail),
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 52,
          titleSpacing: 8,
          leading: const AppBackButton(),
          title: AppPageTitle('scholarship.detail_title'.tr),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: EducationFeedShareIconButton(
                onTap: () => shareService.shareScholarship(scholarshipData),
                size: 36,
                iconSize: 20,
              ),
            ),
            if (!isOwnScholarship && scholarshipDocId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Obx(
                  () => AppHeaderActionButton(
                    onTap: () => scholarshipsController.toggleBookmark(
                      scholarshipDocId,
                      type,
                    ),
                    child: Icon(
                      (scholarshipsController
                                  .bookmarkedScholarships[scholarshipDocId] ??
                              false)
                          ? CupertinoIcons.bookmark_fill
                          : CupertinoIcons.bookmark,
                      color: (scholarshipsController
                                  .bookmarkedScholarships[scholarshipDocId] ??
                              false)
                          ? Colors.orange
                          : Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: PullDownButton(
                itemBuilder: (context) => [
                  if (isOwnScholarship)
                    PullDownMenuItem(
                      onTap: () {
                        noYesAlert(
                          title: 'scholarship.delete_title'.tr,
                          message: 'scholarship.delete_confirm'.tr,
                          onYesPressed: () async {
                            await controller.deleteScholarship(
                              scholarshipDocId,
                              type,
                            );
                          },
                        );
                      },
                      title: 'common.delete'.tr,
                      icon: CupertinoIcons.trash,
                      isDestructive: true,
                    ),
                ],
                buttonBuilder: (context, showMenu) => AppHeaderActionButton(
                  onTap: showMenu,
                  child: const Icon(
                    AppIcons.ellipsisVertical,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              ListView(
                controller: detailScrollController,
                padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                children: [
                  if (galleryImages.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: galleryImages.length == 1
                            ? _buildGalleryImage(galleryImages.first)
                            : PageView.builder(
                                itemCount: galleryImages.length,
                                itemBuilder: (context, pageIndex) {
                                  return _buildGalleryImage(
                                    galleryImages[pageIndex],
                                  );
                                },
                                onPageChanged: controller.updatePageIndex,
                              ),
                      ),
                    ),
                    if (galleryImages.length > 1) ...[
                      const SizedBox(height: 10),
                      _buildPageIndicator(
                        controller: controller,
                        count: galleryImages.length,
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],
                  Text(
                    model.baslik.trim().isEmpty
                        ? 'scholarship.detail_title'.tr
                        : model.baslik.trim(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  if (metaText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      metaText,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildSectionTitle('common.description'.tr),
                  const SizedBox(height: 8),
                  Text.rich(
                    ScholarshipRichText.build(
                      model.aciklama,
                      baseStyle: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        height: 1.45,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildInfoCard(
                    title: 'scholarship.application_info'.tr,
                    children: [
                      _buildInfoRow(
                        'scholarship.published_at'.tr,
                        controller.formatTimestamp(model.timeStamp),
                      ),
                      _buildInfoRow(
                        'scholarship.application_dates_label'.tr,
                        applicationDates,
                      ),
                      if (model.basvuruKosullari.isNotEmpty)
                        _buildInfoRow(
                          'scholarship.conditions_label'.tr,
                          model.basvuruKosullari,
                          rich: true,
                        ),
                      _buildWidgetInfoRow(
                        'scholarship.application_how'.tr,
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    'scholarship.application_via_turqapp_prefix'
                                        .tr,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontFamily: 'MontserratMedium',
                                  height: 1.45,
                                ),
                              ),
                              TextSpan(
                                text: model.basvuruYapilacakYer ==
                                        CreateScholarshipController
                                            .applicationPlaceTurqAppValue
                                    ? 'scholarship.application_received_status'
                                        .tr
                                    : 'scholarship.application_not_received_status'
                                        .tr,
                                style: TextStyle(
                                  color: model.basvuruYapilacakYer ==
                                          CreateScholarshipController
                                              .applicationPlaceTurqAppValue
                                      ? Colors.black
                                      : Colors.red.shade700,
                                  fontSize: 14,
                                  fontFamily: 'MontserratBold',
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildInfoCard(
                    title: 'scholarship.extra_info'.tr,
                    children: [
                      if (requiredDocs.isNotEmpty)
                        _buildInfoRow(
                          'scholarship.required_docs_label'.tr,
                          requiredDocs,
                        ),
                      if (awardMonths.isNotEmpty)
                        _buildInfoRow(
                          'scholarship.award_months_label'.tr,
                          awardMonths,
                        ),
                      _buildInfoRow(
                        'scholarship.other_info'.tr,
                        otherInfo,
                      ),
                    ],
                  ),
                  if (model.universiteler.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _buildInfoCard(
                      title: 'scholarship.universities_label'.tr,
                      children: [
                        Obx(
                          () => Text(
                            controller.showAllUniversities.value
                                ? model.universiteler
                                    .map((e) => '• $e')
                                    .join('\n')
                                : model.universiteler
                                    .take(10)
                                    .map((e) => '• $e')
                                    .join('\n'),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontFamily: 'MontserratMedium',
                              height: 1.45,
                            ),
                          ),
                        ),
                        if (model.universiteler.length > 10) ...[
                          const SizedBox(height: 10),
                          Obx(
                            () => GestureDetector(
                              onTap: () {
                                controller.toggleUniversityList();
                                controller.hiddenUniversityCount.refresh();
                              },
                              child: Text(
                                controller.showAllUniversities.value
                                    ? 'scholarship.show_less'.tr
                                    : 'scholarship.more_universities'.trParams({
                                        'count': controller
                                            .hiddenUniversityCount.value
                                            .toString(),
                                      }),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontFamily: 'MontserratBold',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  PasajOwnerCard(
                    onTap: () => _handleProviderCardTap(
                      website: model.website,
                      userId: userData['userID']?.toString() ?? '',
                    ),
                    title: _truncateLabel(userNick, maxChars: 34),
                    userId: userData['userID']?.toString().trim() ?? '',
                    imageUrl: userImage,
                    subtitle: 'scholarship.visit_website'.tr,
                  ),
                  const SizedBox(height: 16),
                  _buildActionSection(
                    context: context,
                    controller: controller,
                    model: model,
                    scholarshipData: scholarshipData,
                    scholarshipDocId: scholarshipDocId,
                    type: type,
                    userData: userData,
                  ),
                ],
              ),
              if (controller.detailLoading.value)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ScrollTotopButton(
                scrollController: detailScrollController,
                visibilityThreshold: 200,
              ),
            ],
          ),
        ),
      );
    });
  }
}
