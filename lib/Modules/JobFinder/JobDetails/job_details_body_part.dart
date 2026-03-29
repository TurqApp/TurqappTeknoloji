part of 'job_details.dart';

extension JobDetailsBodyPart on _JobDetailsState {
  Widget buildContent(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenJobDetail),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle('pasaj.job_finder.detail_title'.tr),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EducationFeedShareIconButton(
                  onTap: () => shareService.shareJob(controller.model.value),
                  size: 36,
                  iconSize: 18,
                ),
                const SizedBox(width: 6),
                Obx(() {
                  return AppHeaderActionButton(
                    onTap: () =>
                        controller.toggleSave(controller.model.value.docID),
                    size: 36,
                    child: Icon(
                      controller.saved.value ? AppIcons.saved : AppIcons.save,
                      size: 18,
                      color: controller.saved.value
                          ? Colors.orange
                          : Colors.black87,
                    ),
                  );
                }),
                const SizedBox(width: 6),
                pullDownMenu(),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          final current = controller.model.value;
          final title = current.ilanBasligi.isNotEmpty
              ? current.ilanBasligi
              : current.meslek;
          return ListView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
            children: [
              _buildHeroImage(current.logo),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${current.city}, ${current.town}  •  ${current.brand}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontFamily: 'MontserratMedium',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'common.description'.tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 8),
              ClickableTextContent(
                text: current.isTanimi.trim().isEmpty
                    ? 'pasaj.job_finder.no_description'.tr
                    : current.isTanimi,
                startWith7line: true,
                fontSize: 14,
                fontColor: Colors.black87,
                mentionColor: Colors.blue,
                hashtagColor: Colors.blue,
                urlColor: Colors.blue,
                interactiveColor: Colors.blue,
                onHashtagTap: (tag) {
                  if (tag.trim().isEmpty) return;
                  Get.to(() => TagPosts(tag: tag.trim()));
                },
                onUrlTap: (url) async {
                  final uniqueKey =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  await RedirectionLink().goToLink(url, uniqueKey: uniqueKey);
                },
                onMentionTap: (mention) => _openMentionProfile(mention),
              ),
              const SizedBox(height: 18),
              _infoCard(
                title: 'pasaj.job_finder.job_info'.tr,
                children: [
                  _infoRow('common.salary'.tr, _salaryText(current)),
                  _infoRow(
                    'pasaj.job_finder.application_count'.tr,
                    current.applicationCount.toString(),
                  ),
                  _infoRow(
                    'pasaj.job_finder.work_type'.tr,
                    localizeJobDisplayList(current.calismaTuru),
                  ),
                  if (current.calismaGunleri.isNotEmpty)
                    _infoRow(
                      'pasaj.job_finder.work_days'.tr,
                      localizeJobDisplayList(current.calismaGunleri),
                    ),
                  if (current.calismaSaatiBaslangic.isNotEmpty ||
                      current.calismaSaatiBitis.isNotEmpty)
                    _infoRow(
                      'pasaj.job_finder.work_hours'.tr,
                      [
                        current.calismaSaatiBaslangic,
                        current.calismaSaatiBitis,
                      ].where((e) => e.trim().isNotEmpty).join(' - '),
                    ),
                  if (current.pozisyonSayisi > 0)
                    _infoRow(
                      'pasaj.job_finder.personnel_count'.tr,
                      '${current.pozisyonSayisi}',
                    ),
                  if (current.yanHaklar.isNotEmpty)
                    _infoRow(
                      'pasaj.job_finder.benefits'.tr,
                      localizeJobDisplayList(current.yanHaklar),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _infoCard(
                title: 'pasaj.job_finder.listing_info'.tr,
                children: [
                  _infoRow('common.company'.tr, current.brand),
                  _infoRow(
                      'common.city'.tr, '${current.city}, ${current.town}'),
                  _infoRow('common.views'.tr, current.viewCount.toString()),
                  _infoRow(
                    'common.status'.tr,
                    current.ended
                        ? 'pasaj.job_finder.passive'.tr
                        : 'pasaj.market.status.active'.tr,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'common.location'.tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 10),
              _buildLocationPreview(context),
              if (current.adres.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  current.adres,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFF6F7FB),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: current.userID == _currentUid
                          ? null
                          : () => Get.to(
                              () => SocialProfile(userID: current.userID)),
                      child: Row(
                        children: [
                          CachedUserAvatar(
                            userId: current.userID,
                            imageUrl: controller.avatarUrl.value,
                            radius: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        controller.fullname.value.isNotEmpty
                                            ? controller.fullname.value
                                            : current.brand,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontFamily: 'MontserratBold',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    RozetContent(
                                      size: 14,
                                      userID: current.userID,
                                      leftSpacing: 1,
                                    ),
                                  ],
                                ),
                                if (controller.nickname.value.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '@${controller.nickname.value}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (current.userID != _currentUid)
                            const Icon(
                              CupertinoIcons.chevron_right,
                              color: Colors.black38,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildBottomActionSection(controller),
              const SizedBox(height: 18),
              _buildSimilarSection(controller),
              const SizedBox(height: 12),
              const AdmobKare(
                suggestionPlacementId: 'job',
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeroImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1.18,
        child: imageUrl.trim().isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _imageFallback(),
              )
            : _imageFallback(),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFF3F5F7),
      alignment: Alignment.center,
      child: const Icon(
        CupertinoIcons.photo,
        color: Colors.black38,
        size: 36,
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _salaryText(JobModel job) {
    if (job.maas1 <= 0 && job.maas2 <= 0) {
      return 'pasaj.job_finder.salary_not_specified'.tr;
    }
    if (job.maas1 > 0 && job.maas2 > 0 && job.maas2 != job.maas1) {
      return '${NumberFormat.decimalPattern('tr_TR').format(job.maas1)} TL - ${NumberFormat.decimalPattern('tr_TR').format(job.maas2)} TL';
    }
    final salary = job.maas2 > 0 ? job.maas2 : job.maas1;
    return '${NumberFormat.decimalPattern('tr_TR').format(salary)} TL';
  }
}
