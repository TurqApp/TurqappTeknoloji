part of 'booklet_preview.dart';

extension BookletPreviewContentPart on _BookletPreviewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
            children: [
              _buildCoverImage(),
              const SizedBox(height: 14),
              Text(
                controller.model.baslik,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${controller.model.yayinEvi}  •  ${controller.model.sinavTuru}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontFamily: 'MontserratMedium',
                ),
              ),
              const SizedBox(height: 18),
              _infoCard(
                title: 'answer_key.book_info'.tr,
                children: [
                  _infoRow(
                      'answer_key.exam_type'.tr, controller.model.sinavTuru),
                  _infoRow(
                    'answer_key.publisher_hint'.tr,
                    controller.model.yayinEvi,
                  ),
                  _infoRow(
                    'answer_key.publish_date'.tr,
                    controller.model.basimTarihi,
                  ),
                  _infoRow(
                    'common.language'.tr,
                    controller.model.dil.isEmpty ? '-' : controller.model.dil,
                  ),
                  _infoRow(
                    'common.views'.tr,
                    controller.model.viewCount.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildAuthorCard(controller),
              const SizedBox(height: 18),
              _buildAnswerKeysCard(controller),
              const SizedBox(height: 12),
              const AdmobKare(
                key: ValueKey('answer-key-detail-ad-end'),
                suggestionPlacementId: 'answer_key',
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 52,
      titleSpacing: 8,
      leading: const AppBackButton(),
      title: const AppPageTitle(
        'answer_key.book_detail',
        translate: true,
        fontSize: 20,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Obx(
            () => AppHeaderActionButton(
              onTap: controller.toggleBookmark,
              child: Icon(
                controller.isBookmarked.value
                    ? CupertinoIcons.bookmark_fill
                    : CupertinoIcons.bookmark,
                color: controller.isBookmarked.value
                    ? Colors.orange
                    : Colors.black87,
                size: 20,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: _pullDownMenu(controller),
        ),
      ],
    );
  }

  Widget _buildCoverImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 1,
        child: CachedNetworkImage(
          imageUrl: controller.model.cover,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CupertinoActivityIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildAnswerKeysCard(BookletPreviewController controller) {
    return _infoCard(
      title: 'answer_key.answer_keys'.tr,
      children: controller.answerKeys.isEmpty
          ? [
              Text(
                'answer_key.no_answer_keys'.tr,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ]
          : [_buildAnswerKeysList(controller)],
    );
  }
}
