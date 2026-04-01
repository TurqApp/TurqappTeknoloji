part of 'answer_key_content.dart';

extension AnswerKeyContentGridPart on _AnswerKeyContentState {
  void _openOwner(BuildContext context, AnswerKeyContentController controller) {
    controller.openBooklet(context);
  }

  String _publisherLine(AnswerKeyContentController controller) {
    final publisher = controller.model.yayinEvi.trim();
    final publishDate = controller.model.basimTarihi.trim();
    if (publisher.isNotEmpty && publishDate.isNotEmpty) {
      return '$publisher • $publishDate';
    }
    if (publisher.isNotEmpty) return publisher;
    if (publishDate.isNotEmpty) return publishDate;
    return 'answer_key.answer_key_label'.tr;
  }

  Widget _buildMedia(double radius) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: Colors.orange.withValues(alpha: 0.08),
        child: CachedNetworkImage(
          imageUrl: model.cover,
          key: ValueKey(model.cover),
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const Center(
            child: Icon(
              Icons.menu_book_rounded,
              color: Colors.indigo,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
    BuildContext context,
    AnswerKeyContentController controller, {
    double height = 30,
    double fontSize = 15,
  }) {
    return GestureDetector(
      onTap: () => controller.openBooklet(context),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Text(
          'answer_key.inspect'.tr,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    AnswerKeyContentController controller,
  ) {
    return PasajGridCard(
      onTap: () => _openOwner(context, controller),
      media: _buildMedia(12),
      overlay: _buildGridBookmarkOverlay(controller),
      lines: [
        Text(
          controller.model.baslik,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.lineOne,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                controller.model.sinavTuru,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PasajCardStyles.gridLineTwo(
                  PasajCardStyles.lineTwoColor,
                ),
              ),
            ),
          ],
        ),
        Text(
          _publisherLine(controller),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.detail,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                controller.model.dil.isNotEmpty
                    ? controller.model.dil
                    : controller.model.yayinEvi,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PasajCardStyles.gridLineFour(
                  PasajCardStyles.lineFourColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/icons/statsyeni.svg',
              height: 16,
              colorFilter: const ColorFilter.mode(
                PasajCardStyles.lineFourColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              NumberFormatter.format(controller.model.viewCount),
              style: PasajCardStyles.gridLineFour(
                PasajCardStyles.lineFourColor,
              ),
            ),
          ],
        ),
      ],
      cta: _buildPrimaryButton(
        context,
        controller,
        height: PasajListCardMetrics.gridCtaHeight,
        fontSize: PasajListCardMetrics.gridCtaFontSize,
      ),
    );
  }

  Widget _buildGridBookmarkOverlay(AnswerKeyContentController controller) {
    return Obx(
      () => GestureDetector(
        onTap: controller.toggleBookmark,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: PasajListCardMetrics.gridOverlayButtonSize,
          height: PasajListCardMetrics.gridOverlayButtonSize,
          child: Center(
            child: Icon(
              controller.isBookmarked.value
                  ? CupertinoIcons.bookmark_fill
                  : CupertinoIcons.bookmark,
              color: Colors.white,
              size: PasajListCardMetrics.gridOverlayIconSize,
              shadows: const [
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
